import SwiftUI

struct BrowserView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            (theme.isDarkMode ? Color.black : Color(hex: "#F2F2F7"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Браузер")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(theme.isDarkMode ? .white : .black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)

                // Строка поиска
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)

                    TextField("Поиск или URL", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.isDarkMode ? .white : .black)
                        .tint(theme.isDarkMode ? .white : .black)
                        .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.isDarkMode ? Color.white.opacity(0.06) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isSearchFocused
                                        ? (theme.isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.15))
                                        : (theme.isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.06)),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                // Быстрые ссылки
                VStack(alignment: .leading, spacing: 16) {
                    Text("Быстрые ссылки")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
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

                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(theme.isDarkMode ? .white.opacity(0.1) : .black.opacity(0.1))
                    Text("Поиск музыки в интернете")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
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
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: color).opacity(theme.isDarkMode ? 0.15 : 0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: color))
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: color))
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BrowserView()
        .environmentObject(ThemeManager())
}
