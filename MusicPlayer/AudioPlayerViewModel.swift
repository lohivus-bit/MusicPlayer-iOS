import Foundation
import AVFoundation
import Combine

class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var currentTrackIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0      // 0.0 ... 1.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isShuffle: Bool = false
    @Published var isRepeat: Bool = false
    @Published var volume: Float = 0.7
    @Published var likedTracks: Set<UUID> = []

    var tracks: [Track] = sampleTracks
    private var player: AVAudioPlayer?
    private var timer: Timer?

    var currentTrack: Track { tracks[currentTrackIndex] }

    // MARK: - Playback

    func togglePlay() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        // Если плеер уже загружен — просто возобновляем
        if let player = player, player.currentTime > 0 {
            player.play()
            isPlaying = true
            startTimer()
            return
        }
        loadAndPlay(track: currentTrack)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func nextTrack() {
        if isShuffle {
            currentTrackIndex = Int.random(in: 0..<tracks.count)
        } else {
            currentTrackIndex = (currentTrackIndex + 1) % tracks.count
        }
        loadAndPlay(track: currentTrack)
    }

    func previousTrack() {
        // Если прошло больше 3 секунд — перемотать в начало
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        currentTrackIndex = (currentTrackIndex - 1 + tracks.count) % tracks.count
        loadAndPlay(track: currentTrack)
    }

    func selectTrack(at index: Int) {
        currentTrackIndex = index
        loadAndPlay(track: currentTrack)
    }

    func seek(to fraction: Double) {
        guard let player = player else { return }
        player.currentTime = player.duration * fraction
        currentTime = player.currentTime
        progress = fraction
    }

    func setVolume(_ v: Float) {
        volume = v
        player?.volume = v
    }

    func toggleLike() {
        let id = currentTrack.id
        if likedTracks.contains(id) {
            likedTracks.remove(id)
        } else {
            likedTracks.insert(id)
        }
    }

    var isCurrentTrackLiked: Bool {
        likedTracks.contains(currentTrack.id)
    }

    // MARK: - Private

    private func loadAndPlay(track: Track) {
        stopTimer()
        player?.stop()
        player = nil
        progress = 0
        currentTime = 0
        duration = 0

        guard let url = track.url else {
            // Файл не найден — показываем 0 длительность (нет аудио в бандле)
            isPlaying = false
            return
        }

        do {
            // Настраиваем аудиосессию чтобы звук шёл через динамик
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()

            duration = player?.duration ?? 0
            isPlaying = true
            startTimer()
        } catch {
            print("AudioPlayer error: \(error.localizedDescription)")
            isPlaying = false
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.duration = player.duration
            if player.duration > 0 {
                self.progress = player.currentTime / player.duration
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isRepeat {
            seek(to: 0)
            play()
        } else {
            nextTrack()
        }
    }

    // MARK: - Helpers

    func formattedTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
