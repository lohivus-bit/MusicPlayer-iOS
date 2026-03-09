import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @State private var downloadQuality: Int = 1
    @State private var notifications: Bool = true
    @State private var autoPlay: Bool = true
    @State private var crossfade: Bool = false

    var body: some View {
        ZStack {
            (theme.isDarkMode ? Color.black : Color(hex: "#F2F2F7"))
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        Text("Настройки")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                    // Профиль
                    ProfileCard(isDark: theme.isDarkMode)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Секция: Воспроизведение
                    SettingsSection(title: "Воспроизведение", isDark: theme.isDarkMode) {
                        SettingsToggleRow(icon: "play.circle", iconColor: "#8E8E93", title: "Автовоспроизведение", isOn: $autoPlay, isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsToggleRow(icon: "arrow.right.arrow.left", iconColor: "#8E8E93", title: "Кроссфейд", isOn: $crossfade, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: Качество
                    SettingsSection(title: "Качество загрузки", isDark: theme.isDarkMode) {
                        QualityPicker(selected: $downloadQuality, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: Приложение
                    SettingsSection(title: "Приложение", isDark: theme.isDarkMode) {
                        SettingsToggleRow(icon: "moon.fill", iconColor: "#8E8E93", title: "Тёмная тема", isOn: $theme.isDarkMode, isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsToggleRow(icon: "bell.fill", iconColor: "#8E8E93", title: "Уведомления", isOn: $notifications, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: О приложении
                    SettingsSection(title: "О приложении", isDark: theme.isDarkMode) {
                        SettingsInfoRow(icon: "info.circle", iconColor: "#8E8E93", title: "Версия", value: "1.0.0", isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsInfoRow(icon: "swift", iconColor: "#8E8E93", title: "Платформа", value: "SwiftUI", isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: theme.isDarkMode)
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    let isDark: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Аватар
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(hex: "#48484A"), Color(hex: "#3A3A3C")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Пользователь")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(isDark ? .white : .black)
                Text("Настроить профиль")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isDark ? Color.white.opacity(0.05) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let isDark: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .kerning(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDark ? Color.white.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: String
    let title: String
    @Binding var isOn: Bool
    let isDark: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: iconColor).opacity(isDark ? 0.15 : 0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: iconColor))
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDark ? .white : .black)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Color(hex: "#636366"))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: String
    let title: String
    let value: String
    let isDark: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: iconColor).opacity(isDark ? 0.15 : 0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: iconColor))
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDark ? .white : .black)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct SettingsDivider: View {
    let isDark: Bool

    var body: some View {
        Rectangle()
            .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 62)
    }
}

struct QualityPicker: View {
    @Binding var selected: Int
    let isDark: Bool

    private let options = ["Низкое", "Обычное", "Высокое"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selected = i } }) {
                    Text(options[i])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selected == i ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selected == i ? Color(hex: "#48484A") : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
    }
}

#Preview {
    SettingsView(theme: ThemeManager())
        .preferredColorScheme(.dark)
}
