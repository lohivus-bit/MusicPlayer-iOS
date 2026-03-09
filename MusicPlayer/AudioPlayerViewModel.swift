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

    // Pitch / Speed
    @Published var playbackRate: Float = 1.0
    @Published var pitchShift: Float = 0 // in cents (-1200 to +1200)
    @Published var showPitchPicker: Bool = false

    // Slider drag states (prevents timer from fighting with user)
    @Published var isDraggingProgress: Bool = false

    // System volume (read-only, observed)
    @Published var systemVolume: Float = 0.5

    // MARK: - AVAudioEngine
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var timePitchNode = AVAudioUnitTimePitch()
    private var audioFile: AVAudioFile?
    private var seekFrame: AVAudioFramePosition = 0
    private var audioLengthFrames: AVAudioFramePosition = 0
    private var audioSampleRate: Double = 44100

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
        audioEngine.attach(timePitchNode)

        // playerNode -> timePitch -> mainMixer -> output
        audioEngine.connect(playerNode, to: timePitchNode, format: nil)
        audioEngine.connect(timePitchNode, to: audioEngine.mainMixerNode, format: nil)
    }

    // MARK: - System Volume Observation

    private func observeSystemVolume() {
        let session = AVAudioSession.sharedInstance()
        volumeObserver = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.systemVolume = change.newValue ?? 0.5
            }
        }
    }

    // MARK: - Remote Command Center (Lock Screen / Control Center)

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlay()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
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
        let musicDir = docs.appendingPathComponent("ImportedMusic", isDirectory: true)
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
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let destinationURL = self.musicDirectory.appendingPathComponent(url.lastPathComponent)

                if !FileManager.default.fileExists(atPath: destinationURL.path) {
                    do {
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                    } catch {
                        print("Failed to copy file: \(error.localizedDescription)")
                        continue
                    }
                }

                let alreadyExists = self.tracks.contains { $0.fileURL.lastPathComponent == destinationURL.lastPathComponent }
                if alreadyExists { continue }

                if let track = Track.fromFile(url: destinationURL) {
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

        var loadedTracks: [Track] = []
        for fileName in fileNames {
            let fileURL = musicDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let track = Track.fromFile(url: fileURL) {
                    loadedTracks.append(track)
                }
            }
        }
        tracks = loadedTracks
    }

    // MARK: - Track Management

    func removeTrack(at indexSet: IndexSet) {
        for index in indexSet {
            let track = tracks[index]
            try? FileManager.default.removeItem(at: track.fileURL)
        }

        let removingCurrent = indexSet.contains(currentTrackIndex)
        tracks.remove(atOffsets: indexSet)
        saveTrackList()

        if removingCurrent {
            stop()
            if !tracks.isEmpty {
                currentTrackIndex = min(currentTrackIndex, tracks.count - 1)
            } else {
                currentTrackIndex = 0
            }
        } else if currentTrackIndex >= tracks.count {
            currentTrackIndex = max(0, tracks.count - 1)
        }
    }

    func removeTrack(track: Track) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            removeTrack(at: IndexSet(integer: index))
        }
    }

    func moveTrack(from source: IndexSet, to destination: Int) {
        let currentTrack = self.currentTrack
        tracks.move(fromOffsets: source, toOffset: destination)
        saveTrackList()
        if let current = currentTrack,
           let newIndex = tracks.firstIndex(where: { $0.id == current.id }) {
            currentTrackIndex = newIndex
        }
    }

    // MARK: - Playback Controls

    func togglePlay() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard hasTracks else { return }

        if audioFile != nil && !isPlaying {
            // Resume
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
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
        playerNode.stop()
        audioEngine.stop()
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

        if isShuffle {
            var newIndex: Int
            if tracks.count > 1 {
                repeat {
                    newIndex = Int.random(in: 0..<tracks.count)
                } while newIndex == currentTrackIndex
            } else {
                newIndex = 0
            }
            currentTrackIndex = newIndex
        } else {
            currentTrackIndex = (currentTrackIndex + 1) % tracks.count
        }

        if let track = currentTrack {
            loadAndPlay(track: track)
        }
    }

    func previousTrack() {
        guard hasTracks else { return }

        if currentTime > 3 {
            seekToTime(0)
            return
        }

        if isShuffle {
            var newIndex: Int
            if tracks.count > 1 {
                repeat {
                    newIndex = Int.random(in: 0..<tracks.count)
                } while newIndex == currentTrackIndex
            } else {
                newIndex = 0
            }
            currentTrackIndex = newIndex
        } else {
            currentTrackIndex = (currentTrackIndex - 1 + tracks.count) % tracks.count
        }

        if let track = currentTrack {
            loadAndPlay(track: track)
        }
    }

    func selectTrack(at index: Int) {
        guard index >= 0, index < tracks.count else { return }
        currentTrackIndex = index
        loadAndPlay(track: tracks[index])
    }

    func seek(to fraction: Double) {
        guard audioFile != nil else { return }
        let targetFrame = AVAudioFramePosition(Double(audioLengthFrames) * fraction)
        seekToFrame(targetFrame)
    }

    func seekToTime(_ time: TimeInterval) {
        guard audioFile != nil else { return }
        let targetFrame = AVAudioFramePosition(time * audioSampleRate)
        seekToFrame(min(targetFrame, audioLengthFrames))
    }

    private func seekToFrame(_ frame: AVAudioFramePosition) {
        guard let audioFile = audioFile else { return }

        let wasPlaying = isPlaying
        playerNode.stop()

        let clampedFrame = max(0, min(frame, audioLengthFrames))
        seekFrame = clampedFrame

        let remainingFrames = AVAudioFrameCount(audioLengthFrames - clampedFrame)
        guard remainingFrames > 0 else {
            // End of track
            handleTrackFinished()
            return
        }

        playerNode.scheduleSegment(audioFile, startingFrame: clampedFrame, frameCount: remainingFrames, at: nil) { [weak self] in
            DispatchQueue.main.async {
                self?.handleTrackFinished()
            }
        }

        if wasPlaying {
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
            playerNode.play()
        }

        // Update UI immediately
        let newTime = Double(clampedFrame) / audioSampleRate
        currentTime = newTime
        if duration > 0 {
            progress = newTime / duration
        }
        updateNowPlayingInfo()
    }

    // MARK: - Pitch / Speed

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        timePitchNode.rate = rate
        updateNowPlayingInfo()
    }

    func setPitchShift(_ cents: Float) {
        pitchShift = cents
        timePitchNode.pitch = cents
    }

    /// Preset speed options
    static let speedPresets: [(String, Float)] = [
        ("0.5x", 0.5),
        ("0.75x", 0.75),
        ("1.0x", 1.0),
        ("1.25x", 1.25),
        ("1.5x", 1.5),
        ("2.0x", 2.0)
    ]

    // MARK: - Private Playback

    private func loadAndPlay(track: Track) {
        stopTimer()
        playerNode.stop()
        audioEngine.stop()
        audioFile = nil
        progress = 0
        currentTime = 0
        duration = 0
        seekFrame = 0

        let url = track.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("File not found: \(url.path)")
            isPlaying = false
            return
        }

        do {
            setupAudioSession()

            let file = try AVAudioFile(forReading: url)
            audioFile = file
            audioLengthFrames = file.length
            audioSampleRate = file.processingFormat.sampleRate
            duration = Double(file.length) / audioSampleRate

            // Reconnect with correct format
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.disconnectNodeOutput(timePitchNode)
            audioEngine.connect(playerNode, to: timePitchNode, format: file.processingFormat)
            audioEngine.connect(timePitchNode, to: audioEngine.mainMixerNode, format: file.processingFormat)

            // Apply current pitch/speed settings
            timePitchNode.rate = playbackRate
            timePitchNode.pitch = pitchShift

            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handleTrackFinished()
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

    private func handleTrackFinished() {
        guard isPlaying else { return }

        if isRepeat {
            seekToFrame(0)
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
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
            guard let self = self,
                  let nodeTime = self.playerNode.lastRenderTime,
                  let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) else { return }

            // Don't update while user is dragging
            if self.isDraggingProgress { return }

            let currentFrame = self.seekFrame + playerTime.sampleTime
            let time = Double(currentFrame) / self.audioSampleRate
            let dur = self.duration

            DispatchQueue.main.async {
                self.currentTime = max(0, min(time, dur))
                if dur > 0 {
                    self.progress = self.currentTime / dur
                }
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
