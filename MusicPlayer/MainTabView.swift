import SwiftUI

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
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Кастомный таб-бар
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 2)
        .background(
            TabBarBackground()
        )
    }
}

struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.45))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabBarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5)
            }
    }
}

#Preview {
    MainTabView()
}
