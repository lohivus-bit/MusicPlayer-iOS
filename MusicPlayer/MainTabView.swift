import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = true
}

enum Tab: Int, CaseIterable {
    case music
    case browser
    case settings

    var title: String {
        switch self {
        case .music: return "Музыка"
        case .browser: return "Браузер"
        case .settings: return "Настройки"
        }
    }

    var icon: String {
        switch self {
        case .music: return "music.note"
        case .browser: return "globe"
        case .settings: return "gearshape"
        }
    }

    var iconFilled: String {
        switch self {
        case .music: return "music.note"
        case .browser: return "globe"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .music
    @StateObject private var vm = AudioPlayerViewModel()
    @StateObject private var theme = ThemeManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Контент текущего таба
            Group {
                switch selectedTab {
                case .music:
                    MusicView(vm: vm)
                case .browser:
                    BrowserView()
                case .settings:
                    SettingsView(theme: theme)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Плавающий таб-бар в стиле Telegram
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        .environmentObject(theme)
    }
}

// MARK: - Floating Tab Bar (Telegram-style)
struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                FloatingTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: "#1C1C1E"))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
        )
    }
}

struct FloatingTabButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    // Круг-подсветка для активного таба
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.12 : 0))
                        .frame(width: 42, height: 42)

                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : .gray)
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}
