import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit
import UniformTypeIdentifiers

class AudioPlayerViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var tracks: [Track] = []
    @Published var currentTrackIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isShuffle: Bool = false
    @Published var isRepeat: Bool = false
    @Published var isShowingFilePicker: Bool = false
    @Published var isImporting: Bool = false
    @Published var showFullPlayer: Bool = false

    // Speed (slowed / speed up — pitch changes with speed like vinyl)
    @Published var playbackRate: Float = 1.0
    @Published var showPitchPicker: Bool = false

    // Slider drag state
    @Published var isDraggingProgress: Bool = false

    // System volume (observed)
    @Published var systemVolume: Float = 0.5

    // MARK: - AVAudioEngine
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var varispeedNode = AVAudioUnitVarispeed() // Changes speed AND pitch together
    private var audioFile: AVAudioFile?
    private var seekFrame: AVAudioFramePosition = 0
    private var audioLengthFrames: AVAudioFramePosition = 0
    private var audioSampleRate: Double = 44100

    // Generation counter to prevent stale completion handlers from firing
    private var playbackGeneration: Int = 0

    private var timer: Timer?
    private var volumeObserver: NSKeyValueObservation?

    private let savedTracksKey = "savedTrackFileNames"

    // MARK: - Computed Properties

    var currentTrack: Track? {
        guard !tracks.isEmpty, currentTrackIndex >= 0, currentTrackIndex < tracks.count else {
            return nil
        }
        return tracks[currentTrackIndex]
    }

    var hasTracks: Bool { !tracks.isEmpty }

    // MARK: - Init

    override init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
        setupRemoteCommands()
        observeSystemVolume()
        loadSavedTracks()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            systemVolume = session.outputVolume
        } catch {
            print("AudioSession error: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(varispeedNode)

        // playerNode -> varispeed -> mainMixer -> output
        audioEngine.connect(playerNode, to: varispeedNode, format: nil)
        audioEngine.connect(varispeedNode, to: audioEngine.mainMixerNode, format: nil)
    }

    // MARK: - System Volume

    private func observeSystemVolume() {
        let session = AVAudioSession.sharedInstance()
        volumeObserver = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.systemVolume = change.newValue ?? 0.5
            }
        }
    }

    // MARK: - Remote Commands (Lock Screen / Control Center)

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlay(); return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack(); return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack(); return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seekToTime(event.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.albumName,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(playbackRate) : 0.0
        ]

        if let artworkData = track.artworkData, let image = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - File Import

    private var musicDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let musicDir = docs.appendingPathComponent("Music", isDirectory: true)
        if !FileManager.default.fileExists(atPath: musicDir.path) {
            try? FileManager.default.createDirectory(at: musicDir, withIntermediateDirectories: true)
        }
        return musicDir
    }

    func importFiles(urls: [URL]) {
        isImporting = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var newTracks: [Track] = []

            for url in urls {
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                }

                let destURL = self.musicDirectory.appendingPathComponent(url.lastPathComponent)

                if !FileManager.default.fileExists(atPath: destURL.path) {
                    do {
                        try FileManager.default.copyItem(at: url, to: destURL)
                    } catch {
                        print("Copy failed: \(error.localizedDescription)")
                        continue
                    }
                }

                let alreadyExists = self.tracks.contains { $0.fileURL.lastPathComponent == destURL.lastPathComponent }
                if alreadyExists { continue }

                if let track = Track.fromFile(url: destURL) {
                    newTracks.append(track)
                }
            }

            DispatchQueue.main.async {
                self.tracks.append(contentsOf: newTracks)
                self.saveTrackList()
                self.isImporting = false
            }
        }
    }

    // MARK: - Persistence

    private func saveTrackList() {
        let fileNames = tracks.map { $0.fileURL.lastPathComponent }
        UserDefaults.standard.set(fileNames, forKey: savedTracksKey)
    }

    private func loadSavedTracks() {
        guard let fileNames = UserDefaults.standard.stringArray(forKey: savedTracksKey) else { return }
        var loaded: [Track] = []
        for name in fileNames {
            let url = musicDirectory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path),
               let track = Track.fromFile(url: url) {
                loaded.append(track)
            }
        }
        tracks = loaded
    }

    // MARK: - Track Management

    func removeTrack(at indexSet: IndexSet) {
        for index in indexSet {
            try? FileManager.default.removeItem(at: tracks[index].fileURL)
        }
        let removingCurrent = indexSet.contains(currentTrackIndex)
        tracks.remove(atOffsets: indexSet)
        saveTrackList()

        if removingCurrent {
            stop()
            currentTrackIndex = tracks.isEmpty ? 0 : min(currentTrackIndex, tracks.count - 1)
        } else if currentTrackIndex >= tracks.count {
            currentTrackIndex = max(0, tracks.count - 1)
        }
    }

    func removeTrack(track: Track) {
        if let i = tracks.firstIndex(where: { $0.id == track.id }) {
            removeTrack(at: IndexSet(integer: i))
        }
    }

    // MARK: - Playback Controls

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard hasTracks else { return }

        // Resume if paused
        if audioFile != nil && !isPlaying {
            if !audioEngine.isRunning { try? audioEngine.start() }
            playerNode.play()
            isPlaying = true
            startTimer()
            updateNowPlayingInfo()
            return
        }

        guard let track = currentTrack else { return }
        loadAndPlay(track: track)
    }

    func pause() {
        playerNode.pause()
        isPlaying = false
        stopTimer()
        updateNowPlayingInfo()
    }

    func stop() {
        playbackGeneration += 1 // Invalidate any pending completion handlers
        playerNode.stop()
        if audioEngine.isRunning { audioEngine.stop() }
        audioFile = nil
        isPlaying = false
        stopTimer()
        progress = 0
        currentTime = 0
        duration = 0
        updateNowPlayingInfo()
    }

    func nextTrack() {
        guard hasTracks else { return }

        if isShuffle && tracks.count > 1 {
            var idx: Int
            repeat { idx = Int.random(in: 0..<tracks.count) } while idx == currentTrackIndex
            currentTrackIndex = idx
        } else {
            currentTrackIndex = (currentTrackIndex + 1) % tracks.count
        }

        if let track = currentTrack { loadAndPlay(track: track) }
    }

    func previousTrack() {
        guard hasTracks else { return }

        if currentTime > 3 {
            seekToTime(0)
            return
        }

        if isShuffle && tracks.count > 1 {
            var idx: Int
            repeat { idx = Int.random(in: 0..<tracks.count) } while idx == currentTrackIndex
            currentTrackIndex = idx
        } else {
            currentTrackIndex = (currentTrackIndex - 1 + tracks.count) % tracks.count
        }

        if let track = currentTrack { loadAndPlay(track: track) }
    }

    func selectTrack(at index: Int) {
        guard index >= 0, index < tracks.count else { return }
        currentTrackIndex = index
        loadAndPlay(track: tracks[index])
    }

    func seek(to fraction: Double) {
        guard audioFile != nil else { return }
        let frame = AVAudioFramePosition(Double(audioLengthFrames) * max(0, min(1, fraction)))
        seekToFrame(frame)
    }

    func seekToTime(_ time: TimeInterval) {
        guard audioFile != nil else { return }
        let frame = AVAudioFramePosition(time * audioSampleRate)
        seekToFrame(min(max(0, frame), audioLengthFrames))
    }

    private func seekToFrame(_ frame: AVAudioFramePosition) {
        guard let file = audioFile else { return }

        let wasPlaying = isPlaying
        playerNode.stop() // Don't increment generation here — we want to reschedule

        let clamped = max(0, min(frame, audioLengthFrames))
        seekFrame = clamped

        let remaining = AVAudioFrameCount(audioLengthFrames - clamped)
        guard remaining > 0 else {
            onTrackFinished()
            return
        }

        let gen = playbackGeneration
        playerNode.scheduleSegment(file, startingFrame: clamped, frameCount: remaining, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.playbackGeneration == gen else { return }
                self.onTrackFinished()
            }
        }

        if wasPlaying {
            if !audioEngine.isRunning { try? audioEngine.start() }
            playerNode.play()
        }

        currentTime = Double(clamped) / audioSampleRate
        if duration > 0 { progress = currentTime / duration }
        updateNowPlayingInfo()
    }

    // MARK: - Speed (Slowed / Speed Up)

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        varispeedNode.rate = rate
        updateNowPlayingInfo()
    }

    /// Presets for slowed / speed up
    static let speedPresets: [(String, Float)] = [
        ("0.5x", 0.5),
        ("0.75x", 0.75),
        ("0.85x", 0.85),
        ("1.0x", 1.0),
        ("1.25x", 1.25),
        ("1.5x", 1.5),
        ("2.0x", 2.0)
    ]

    // MARK: - Private Playback

    private func loadAndPlay(track: Track) {
        stopTimer()
        playbackGeneration += 1 // Invalidate old completion handlers
        playerNode.stop()
        if audioEngine.isRunning { audioEngine.stop() }
        audioFile = nil
        progress = 0
        currentTime = 0
        duration = 0
        seekFrame = 0

        guard FileManager.default.fileExists(atPath: track.fileURL.path) else {
            print("File not found: \(track.fileURL.path)")
            isPlaying = false
            return
        }

        do {
            setupAudioSession()

            let file = try AVAudioFile(forReading: track.fileURL)
            audioFile = file
            audioLengthFrames = file.length
            audioSampleRate = file.processingFormat.sampleRate
            duration = Double(file.length) / audioSampleRate

            // Reconnect with correct format
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.disconnectNodeOutput(varispeedNode)
            audioEngine.connect(playerNode, to: varispeedNode, format: file.processingFormat)
            audioEngine.connect(varispeedNode, to: audioEngine.mainMixerNode, format: file.processingFormat)

            varispeedNode.rate = playbackRate

            let gen = playbackGeneration
            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    // Only handle if this is still the current generation
                    guard let self = self, self.playbackGeneration == gen else { return }
                    self.onTrackFinished()
                }
            }

            try audioEngine.start()
            playerNode.play()

            isPlaying = true
            startTimer()
            updateNowPlayingInfo()
        } catch {
            print("AudioEngine error: \(error.localizedDescription)")
            isPlaying = false
        }
    }

    private func onTrackFinished() {
        guard isPlaying else { return }
        if isRepeat {
            seekToFrame(0)
            if !audioEngine.isRunning { try? audioEngine.start() }
            playerNode.play()
            isPlaying = true
            startTimer()
        } else {
            nextTrack()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isDraggingProgress,
                  let nodeTime = self.playerNode.lastRenderTime,
                  let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) else { return }

            let frame = self.seekFrame + playerTime.sampleTime
            let time = Double(frame) / self.audioSampleRate
            let dur = self.duration

            DispatchQueue.main.async {
                self.currentTime = max(0, min(time, dur))
                if dur > 0 { self.progress = self.currentTime / dur }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Helpers

    func formattedTime(_ t: TimeInterval) -> String {
        guard !t.isNaN && !t.isInfinite else { return "0:00" }
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    static var supportedTypes: [UTType] {
        [.mp3, .mpeg4Audio, .audio, .aiff, .wav]
    }
}
