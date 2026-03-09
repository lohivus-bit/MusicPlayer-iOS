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
                    HStack {
                        Text("Настройки")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(theme.isDarkMode ? .white : .black)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                    ProfileCard(isDark: theme.isDarkMode)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    SettingsSection(title: "Воспроизведение", isDark: theme.isDarkMode) {
                        SettingsToggleRow(icon: "play.circle", iconColor: "#34C759", title: "Автовоспроизведение", isOn: $autoPlay, isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsToggleRow(icon: "arrow.right.arrow.left", iconColor: "#007AFF", title: "Кроссфейд", isOn: $crossfade, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    SettingsSection(title: "Качество загрузки", isDark: theme.isDarkMode) {
                        QualityPicker(selected: $downloadQuality, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    SettingsSection(title: "Приложение", isDark: theme.isDarkMode) {
                        SettingsToggleRow(icon: "moon.fill", iconColor: "#5856D6", title: "Тёмная тема", isOn: $theme.isDarkMode, isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsToggleRow(icon: "bell.fill", iconColor: "#FF9500", title: "Уведомления", isOn: $notifications, isDark: theme.isDarkMode)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    SettingsSection(title: "О приложении", isDark: theme.isDarkMode) {
                        SettingsInfoRow(icon: "info.circle", iconColor: "#007AFF", title: "Версия", value: "1.0.0", isDark: theme.isDarkMode)
                        SettingsDivider(isDark: theme.isDarkMode)
                        SettingsInfoRow(icon: "swift", iconColor: "#FF6B35", title: "Платформа", value: "SwiftUI", isDark: theme.isDarkMode)
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(hex: "#5856D6"), Color(hex: "#AF52DE")], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .fill(Color(hex: iconColor).opacity(isDark ? 0.2 : 0.12))
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
                .tint(Color(hex: "#5856D6"))
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
                    .fill(Color(hex: iconColor).opacity(isDark ? 0.2 : 0.12))
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
                                .fill(selected == i ? Color(hex: "#5856D6") : Color.clear)
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
}
