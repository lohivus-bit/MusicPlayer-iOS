import SwiftUI

// MARK: - Music View (главный экран с музыкой)
struct MusicView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            // Фон
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
                MusicHeaderView()

                ScrollView {
                    VStack(spacing: 20) {
                        NowPlayingCard(vm: vm)
                        TrackListView(vm: vm)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Header
struct MusicHeaderView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Музыка")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                Text("\(sampleTracks.count) треков")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.isDarkMode ? .white : .black)
                .padding(10)
                .background(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Now Playing Card
struct NowPlayingCard: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("NOW PLAYING")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 4)

            AlbumArtView(track: vm.currentTrack, isPlaying: vm.isPlaying)
                .padding(.bottom, 16)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.currentTrack.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(theme.isDarkMode ? .white : .black)
                    Text(vm.currentTrack.artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { vm.toggleLike() }) {
                    Image(systemName: vm.isCurrentTrackLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(vm.isCurrentTrackLiked ? .red : .gray.opacity(0.5))
                        .scaleEffect(vm.isCurrentTrackLiked ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.isCurrentTrackLiked)
                }
            }
            .padding(.bottom, 14)

            ProgressBarView(vm: vm)
                .padding(.bottom, 18)

            ControlsView(vm: vm)
                .padding(.bottom, 14)

            VolumeView(vm: vm)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Album Art
struct AlbumArtView: View {
    let track: Track
    let isPlaying: Bool
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: track.colorHex), Color(hex: track.colorHex).opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: Color(hex: track.colorHex).opacity(0.4), radius: 20, y: 10)

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 100, height: 100)

                ForEach([40, 55, 70, 85] as [CGFloat], id: \.self) { size in
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: size, height: size)
                }

                Circle()
                    .fill(Color(hex: track.colorHex))
                    .frame(width: 16, height: 16)
            }
            .rotationEffect(.degrees(rotation))
            .onAppear { if isPlaying { startRotation() } }
            .onChange(of: isPlaying) { playing in
                if playing { startRotation() }
            }

            Text(track.emoji)
                .font(.system(size: 36))
                .offset(x: 48, y: -48)
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }

    private func startRotation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

// MARK: - Progress Bar
struct ProgressBarView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        .frame(height: 4)
                    Capsule()
                        .fill(theme.isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.7))
                        .frame(width: geo.size.width * vm.progress, height: 4)
                    Circle()
                        .fill(theme.isDarkMode ? Color.white : Color.black)
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, geo.size.width * vm.progress - 6))
                        .shadow(color: .black.opacity(0.2), radius: 4)
                }
            }
            .frame(height: 12)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let geo = UIScreen.main.bounds.width - 72
                        let fraction = max(0, min(1, v.location.x / geo))
                        vm.seek(to: fraction)
                    }
            )

            HStack {
                Text(vm.formattedTime(vm.currentTime))
                Spacer()
                Text(vm.formattedTime(vm.duration))
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.gray)
        }
    }
}

// MARK: - Controls
struct ControlsView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    private var fg: Color { theme.isDarkMode ? .white : .black }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { vm.isShuffle.toggle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(vm.isShuffle ? fg : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(fg)
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.togglePlay() }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.isDarkMode
                                    ? [Color(hex: "#3A3A3C"), Color(hex: "#2C2C2E")]
                                    : [Color(hex: "#E5E5EA"), Color(hex: "#D1D1D6")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 66, height: 66)
                        .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
                        .overlay(
                            Circle()
                                .stroke(theme.isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.6), lineWidth: 1)
                        )

                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(fg)
                        .offset(x: vm.isPlaying ? 0 : 2)
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(vm.isPlaying ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.isPlaying)

            Button(action: { vm.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(fg)
            }
            .frame(maxWidth: .infinity)

            Button(action: { vm.isRepeat.toggle() }) {
                Image(systemName: "repeat")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(vm.isRepeat ? fg : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Volume
struct VolumeView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
                        .frame(height: 3)
                    Capsule()
                        .fill(theme.isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(vm.volume), height: 3)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let fraction = max(0, min(1, Float(v.location.x / geo.size.width)))
                            vm.setVolume(fraction)
                        }
                )
            }
            .frame(height: 3)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}

// MARK: - Track List
struct TrackListView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Далее")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(theme.isDarkMode ? .white : .black)
                Spacer()
                Text("Все")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)

            ForEach(Array(vm.tracks.enumerated()), id: \.1.id) { i, track in
                TrackRow(
                    track: track,
                    index: i,
                    isActive: i == vm.currentTrackIndex,
                    isPlaying: vm.isPlaying && i == vm.currentTrackIndex
                ) {
                    vm.selectTrack(at: i)
                }
            }
        }
        .padding(.bottom, 10)
    }
}

struct TrackRow: View {
    let track: Track
    let index: Int
    let isActive: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: track.colorHex).opacity(0.6))
                    Text(track.emoji).font(.system(size: 20))
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.isDarkMode ? .white : .black)
                    Text(track.artist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()

                if isPlaying {
                    EqualizerView()
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? (theme.isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06)) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Equalizer animation
struct EqualizerView: View {
    @State private var heights: [CGFloat] = [4, 10, 7]
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(theme.isDarkMode ? Color.white : Color.black)
                    .frame(width: 3, height: heights[i])
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.13),
                        value: heights[i]
                    )
            }
        }
        .frame(width: 20, height: 16)
        .onAppear {
            heights = [14, 6, 12]
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
