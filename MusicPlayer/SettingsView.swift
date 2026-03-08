import SwiftUI

struct SettingsView: View {
    @State private var downloadQuality: Int = 1  // 0=low, 1=normal, 2=high
    @State private var darkMode: Bool = true
    @State private var notifications: Bool = true
    @State private var autoPlay: Bool = true
    @State private var crossfade: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        Text("Настройки")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                    // Профиль
                    ProfileCard()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Секция: Воспроизведение
                    SettingsSection(title: "Воспроизведение") {
                        SettingsToggleRow(icon: "play.circle", iconColor: "#6b21a8", title: "Автовоспроизведение", isOn: $autoPlay)
                        SettingsDivider()
                        SettingsToggleRow(icon: "arrow.right.arrow.left", iconColor: "#1d4ed8", title: "Кроссфейд", isOn: $crossfade)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: Качество
                    SettingsSection(title: "Качество загрузки") {
                        QualityPicker(selected: $downloadQuality)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: Приложение
                    SettingsSection(title: "Приложение") {
                        SettingsToggleRow(icon: "moon.fill", iconColor: "#6b21a8", title: "Тёмная тема", isOn: $darkMode)
                        SettingsDivider()
                        SettingsToggleRow(icon: "bell.fill", iconColor: "#b45309", title: "Уведомления", isOn: $notifications)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Секция: О приложении
                    SettingsSection(title: "О приложении") {
                        SettingsInfoRow(icon: "info.circle", iconColor: "#065f46", title: "Версия", value: "1.0.0")
                        SettingsDivider()
                        SettingsInfoRow(icon: "swift", iconColor: "#FF6B35", title: "Платформа", value: "SwiftUI")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Отступ под таб-бар
                }
            }
        }
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Аватар
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Пользователь")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text("Настроить профиль")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.purple)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .kerning(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: iconColor).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: iconColor))
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.purple)
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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: iconColor).opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: iconColor))
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 62)
    }
}

struct QualityPicker: View {
    @Binding var selected: Int

    private let options = ["Низкое", "Обычное", "Высокое"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selected = i } }) {
                    Text(options[i])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selected == i ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selected == i ? Color.purple.opacity(0.5) : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
