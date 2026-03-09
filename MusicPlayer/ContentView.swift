import SwiftUI
import UIKit
import MediaPlayer

// MARK: - Music View (главный экран — только плейлист)
struct MusicView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            Group {
                if theme.isDarkMode {
                    LinearGradient(
                        colors: [Color(hex: "#2C2C2E").opacity(0.8), Color.black],
                        startPoint: .top, endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: [Color(hex: "#E5E5EA"), Color(hex: "#F2F2F7")],
                        startPoint: .top, endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                MusicHeaderView(vm: vm)

                if vm.hasTracks {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(vm.tracks.enumerated()), id: \.1.id) { i, track in
                                TrackRow(
                                    track: track,
                                    index: i,
                                    isActive: i == vm.currentTrackIndex,
                                    isPlaying: vm.isPlaying && i == vm.currentTrackIndex,
                                    onTap: { vm.selectTrack(at: i) },
                                    onDelete: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            vm.removeTrack(track: track)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, vm.hasTracks ? 140 : 100) // space for mini player + tab bar
                    }
                } else {
                    EmptyMusicView(vm: vm)
                }
            }

            // Import overlay
            if vm.isImporting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Импорт треков...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
                }
            }
        }
        .sheet(isPresented: $vm.isShowingFilePicker) {
            DocumentPickerView(
                onPick: { urls in vm.importFiles(urls: urls) },
                onCancel: { }
            )
        }
        .sheet(isPresented: $vm.showFullPlayer) {
            FullPlayerView(vm: vm)
                .environmentObject(theme)
        }
    }
}

// MARK: - Empty State
struct EmptyMusicView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
                    .frame(width: 120, height: 120)
                Image(systemName: "music.note.list")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(theme.isDarkMode ? .white.opacity(0.2) : .black.opacity(0.2))
            }

            VStack(spacing: 8) {
                Text("Нет треков")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                Text("Добавьте музыку из файлов iPhone")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }

            Button(action: { vm.isShowingFilePicker = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 20))
                    Text("Добавить файлы").font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: [Color(hex: "#5856D6"), Color(hex: "#AF52DE")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                )
            }

            Spacer()
        }
    }
}

// MARK: - Header
struct MusicHeaderView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Музыка")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                Text("\(vm.tracks.count) \(trackCountString(vm.tracks.count))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: { vm.isShowingFilePicker = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                    .padding(10)
                    .background(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func trackCountString(_ count: Int) -> String {
        let mod100 = count % 100
        let mod10 = count % 10
        if mod100 >= 11 && mod100 <= 19 { return "треков" }
        switch mod10 {
        case 1: return "трек"
        case 2, 3, 4: return "трека"
        default: return "треков"
        }
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: Track
    let index: Int
    let isActive: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var theme: ThemeManager
    @State private var offset: CGFloat = 0
    @State private var showDelete: Bool = false

    var body: some View {
        ZStack(alignment: .trailing) {
            if showDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 64)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                }
            }

            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        if let artworkData = track.artworkData, let uiImage = UIImage(data: artworkData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(theme.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.2))
                        }
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isActive ? Color(hex: "#5856D6") : (theme.isDarkMode ? .white : .black))
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    Spacer()

                    if isPlaying {
                        EqualizerView()
                    } else {
                        Text(track.formattedDuration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isActive
                              ? (theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                              : (theme.isDarkMode ? Color.white.opacity(0.03) : Color.white.opacity(0.5)))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        } else if showDelete {
                            offset = min(0, -80 + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if value.translation.width < -40 {
                                offset = -80
                                showDelete = true
                            } else {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Equalizer
struct EqualizerView: View {
    @State private var heights: [CGFloat] = [4, 10, 7]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color(hex: "#5856D6"))
                    .frame(width: 3, height: heights[i])
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.13),
                        value: heights[i]
                    )
            }
        }
        .frame(width: 20, height: 16)
        .onAppear { heights = [14, 6, 12] }
    }
}

// MARK: - Mini Player Bar
struct MiniPlayerBar: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        if let track = vm.currentTrack {
            Button(action: { vm.showFullPlayer = true }) {
                HStack(spacing: 12) {
                    // Artwork
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                        if let data = track.artworkData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 40, height: 40)

                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Play / Pause
                    Button(action: { vm.togglePlay() }) {
                        Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                    }

                    // Next
                    Button(action: { vm.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)

            // Mini progress bar
            GeometryReader { geo in
                Capsule()
                    .fill(Color(hex: "#5856D6"))
                    .frame(width: geo.size.width * vm.progress, height: 2)
            }
            .frame(height: 2)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Full Player View (Sheet)
struct FullPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            (theme.isDarkMode ? Color.black : Color(hex: "#F2F2F7"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator + close
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("NOW PLAYING")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(2)
                        .foregroundColor(.gray)
                    Spacer()
                    // Speed indicator - always visible
                    Text(String(format: "%.1fx", vm.playbackRate))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#5856D6"))
                        .opacity(vm.playbackRate != 1.0 ? 1.0 : 0.5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Album Art — larger, less horizontal padding
                FullPlayerArtwork(track: vm.currentTrack)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 20)

                // Track info + pitch button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.currentTrack?.title ?? "Нет трека")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                            .lineLimit(1)
                        Text(vm.currentTrack?.artist ?? "—")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    Spacer()
                    // Pitch / Speed button
                    Button(action: { vm.showPitchPicker.toggle() }) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 22))
                            .foregroundColor(vm.playbackRate != 1.0 ? Color(hex: "#5856D6") : .gray.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Progress slider
                FullProgressBar(vm: vm)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Controls
                FullControlsView(vm: vm)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Volume (system)
                SystemVolumeSlider()
                    .frame(height: 30)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $vm.showPitchPicker) {
            SpeedPickerView(vm: vm)
                .presentationDetents([.height(280)])
                .environmentObject(theme)
        }
    }
}

// MARK: - Full Player Artwork
struct FullPlayerArtwork: View {
    let track: Track?
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.isDarkMode ? Color(hex: "#3A3A3C") : Color(hex: "#D1D1D6"),
                            theme.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#E5E5EA")
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

            if let track = track, let data = track.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.3))
                        .frame(width: 100, height: 100)
                    Image(systemName: "music.note")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(theme.isDarkMode ? .white.opacity(0.3) : .black.opacity(0.2))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Full Progress Bar (smooth, no lag)
struct FullProgressBar: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager
    @State private var dragProgress: Double = 0

    private var displayProgress: Double {
        vm.isDraggingProgress ? dragProgress : vm.progress
    }

    private var displayTime: TimeInterval {
        vm.isDraggingProgress ? dragProgress * vm.duration : vm.currentTime
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
                        .frame(height: 6)

                    Capsule()
                        .fill(theme.isDarkMode ? Color.white : Color.black.opacity(0.8))
                        .frame(width: geo.size.width * displayProgress, height: 6)

                    Circle()
                        .fill(theme.isDarkMode ? Color.white : Color.black)
                        .frame(width: vm.isDraggingProgress ? 20 : 14, height: vm.isDraggingProgress ? 20 : 14)
                        .offset(x: max(0, geo.size.width * displayProgress - (vm.isDraggingProgress ? 10 : 7)))
                        .shadow(color: .black.opacity(0.2), radius: 3)
                        .animation(.easeOut(duration: 0.1), value: vm.isDraggingProgress)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            vm.isDraggingProgress = true
                            dragProgress = max(0, min(1, v.location.x / geo.size.width))
                        }
                        .onEnded { v in
                            let fraction = max(0, min(1, v.location.x / geo.size.width))
                            vm.seek(to: fraction)
                            vm.isDraggingProgress = false
                        }
                )
            }
            .frame(height: 20)

            HStack {
                Text(vm.formattedTime(displayTime))
                Spacer()
                Text("-" + vm.formattedTime(max(0, vm.duration - displayTime)))
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.gray)
        }
    }
}

// MARK: - Full Controls
struct FullControlsView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    private var fg: Color { theme.isDarkMode ? .white : .black }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { vm.isShuffle.toggle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(vm.isShuffle ? fg : .gray.opacity(0.4))
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(fg)
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.togglePlay() }) {
                Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(fg)
                    .frame(width: 70, height: 70)
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(fg)
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.isRepeat.toggle() }) {
                Image(systemName: vm.isRepeat ? "repeat.1" : "repeat")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(vm.isRepeat ? fg : .gray.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - System Volume Slider (uses MPVolumeView)
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsRouteButton = true
        volumeView.setVolumeThumbImage(UIImage(), for: .normal) // Hide default thumb, use slider track
        // Style the slider
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumTrackTintColor = .white
            slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.15)
        }
        return volumeView
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

// MARK: - Speed Picker
struct SpeedPickerView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            (theme.isDarkMode ? Color(hex: "#1C1C1E") : Color(hex: "#F2F2F7"))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Скорость воспроизведения")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                    .padding(.top, 8)

                // Speed presets
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AudioPlayerViewModel.speedPresets, id: \.1) { label, rate in
                        Button(action: {
                            vm.setPlaybackRate(rate)
                        }) {
                            Text(label)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(vm.playbackRate == rate ? .white : (theme.isDarkMode ? .white : .black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(vm.playbackRate == rate
                                              ? Color(hex: "#5856D6")
                                              : (theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Reset button
                Button(action: {
                    vm.setPlaybackRate(1.0)
                    dismiss()
                }) {
                    Text("Сбросить")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Color extension
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    MainTabView()
}
