import SwiftUI

// MARK: - Music View (главный экран с музыкой)
struct MusicView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        ZStack {
            // Фон
            LinearGradient(
                colors: [Color(hex: vm.currentTrack.colorHex).opacity(0.6), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: vm.currentTrackIndex)

            VStack(spacing: 0) {
                // Заголовок
                MusicHeaderView()

                ScrollView {
                    VStack(spacing: 20) {
                        // Карточка "Now Playing"
                        NowPlayingCard(vm: vm)

                        // Список треков
                        TrackListView(vm: vm)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90) // Отступ под таб-бар
                }
            }
        }
    }
}

// MARK: - Header
struct MusicHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Музыка")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                Text("\(sampleTracks.count) треков")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.1))
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

    var body: some View {
        VStack(spacing: 0) {
            // Надпись NOW PLAYING
            HStack {
                Spacer()
                Text("NOW PLAYING")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(2)
                    .foregroundColor(.purple.opacity(0.7))
            }
            .padding(.bottom, 4)

            // Обложка
            AlbumArtView(track: vm.currentTrack, isPlaying: vm.isPlaying)
                .padding(.bottom, 16)

            // Название + лайк
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.currentTrack.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    Text(vm.currentTrack.artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Button(action: { vm.toggleLike() }) {
                    Image(systemName: vm.isCurrentTrackLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(vm.isCurrentTrackLiked ? .red : .white.opacity(0.4))
                        .scaleEffect(vm.isCurrentTrackLiked ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: vm.isCurrentTrackLiked)
                }
            }
            .padding(.bottom, 14)

            // Прогресс бар
            ProgressBarView(vm: vm)
                .padding(.bottom, 18)

            // Кнопки управления
            ControlsView(vm: vm)
                .padding(.bottom, 14)

            // Громкость
            VolumeView(vm: vm)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
            // Фон обложки
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: track.colorHex), Color(hex: track.colorHex).opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: Color(hex: track.colorHex).opacity(0.5), radius: 20, y: 10)

            // Виниловая пластинка
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 100, height: 100)

                // Кольца
                ForEach([40, 55, 70, 85] as [CGFloat], id: \.self) { size in
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: size, height: size)
                }

                // Центр
                Circle()
                    .fill(Color(hex: track.colorHex))
                    .frame(width: 16, height: 16)
            }
            .rotationEffect(.degrees(rotation))
            .onAppear { if isPlaying { startRotation() } }
            .onChange(of: isPlaying) { playing in
                if playing { startRotation() }
            }

            // Эмодзи
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

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 4)
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * vm.progress, height: 4)
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, geo.size.width * vm.progress - 6))
                        .shadow(color: .purple, radius: 4)
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
            .foregroundColor(.white.opacity(0.45))
        }
    }
}

// MARK: - Controls
struct ControlsView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Shuffle
            Button(action: { vm.isShuffle.toggle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(vm.isShuffle ? .purple : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)

            // Prev
            Button(action: { vm.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Play/Pause
            Button(action: { vm.togglePlay() }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 66, height: 66)
                        .shadow(color: .purple.opacity(0.6), radius: 14, y: 6)

                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: vm.isPlaying ? 0 : 2)
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(vm.isPlaying ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.isPlaying)

            // Next
            Button(action: { vm.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            // Repeat
            Button(action: { vm.isRepeat.toggle() }) {
                Image(systemName: "repeat")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(vm.isRepeat ? .purple : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Volume
struct VolumeView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
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
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Track List
struct TrackListView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Далее")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                Text("Все")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
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

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Мини-обложка
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: track.colorHex).opacity(0.6))
                    Text(track.emoji).font(.system(size: 20))
                }
                .frame(width: 46, height: 46)

                // Инфо
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isActive ? .purple : .white)
                    Text(track.artist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()

                // Эквалайзер или номер
                if isPlaying {
                    EqualizerView()
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.purple.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Equalizer animation
struct EqualizerView: View {
    @State private var heights: [CGFloat] = [4, 10, 7]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(Color.purple)
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
