import SwiftUI

struct BrowserView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            // Фон
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Заголовок
                HStack {
                    Text("Браузер")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)

                // Строка поиска
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    TextField("Поиск или URL", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .tint(.purple)
                        .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSearchFocused ? Color.purple.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                // Быстрые ссылки
                VStack(alignment: .leading, spacing: 16) {
                    Text("Быстрые ссылки")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 20) {
                        QuickLinkItem(icon: "play.circle.fill", title: "YouTube", color: "#FF0000")
                        QuickLinkItem(icon: "music.note.house.fill", title: "Spotify", color: "#1DB954")
                        QuickLinkItem(icon: "cloud.fill", title: "SoundCloud", color: "#FF5500")
                        QuickLinkItem(icon: "headphones", title: "Deezer", color: "#A238FF")
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Плейсхолдер
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.white.opacity(0.15))
                    Text("Поиск музыки в интернете")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }

                Spacer()
            }
        }
    }
}

struct QuickLinkItem: View {
    let icon: String
    let title: String
    let color: String

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: color).opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: color))
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BrowserView()
        .preferredColorScheme(.dark)
}
