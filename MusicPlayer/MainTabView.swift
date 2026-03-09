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

            // Mini player + Tab bar stack
            VStack(spacing: 6) {
                // Mini player (only on non-music tabs, or always if has tracks)
                if vm.hasTracks {
                    MiniPlayerBar(vm: vm)
                }

                // Tab bar
                LiquidGlassTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        .environmentObject(theme)
    }
}

// MARK: - Liquid Glass Tab Bar
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Tab
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                LiquidTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, theme.isDarkMode ? .dark : .light)
                .overlay(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDarkMode ? 0.15 : 0.6),
                                    Color.white.opacity(theme.isDarkMode ? 0.05 : 0.3)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDarkMode ? 0.3 : 0.8),
                                    Color.white.opacity(theme.isDarkMode ? 0.08 : 0.2)
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
                .shadow(color: .white.opacity(theme.isDarkMode ? 0.05 : 0.2), radius: 1, y: -1)
        )
    }
}

struct LiquidTabButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDarkMode ? 0.2 : 0.5),
                                        Color.white.opacity(theme.isDarkMode ? 0.06 : 0.15)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 36, height: 36)
                    }

                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(
                            isSelected
                                ? (theme.isDarkMode ? .white : .black)
                                : .gray
                        )
                }
                .frame(height: 36)

                Text(tab.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(
                        isSelected
                            ? (theme.isDarkMode ? .white : .black)
                            : .gray
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainTabView()
}
