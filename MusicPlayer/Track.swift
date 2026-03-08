import Foundation

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let fileName: String   // имя файла в папке Resources (без расширения)
    let fileExtension: String  // расширение: "mp3", "m4a", и т.д.
    let emoji: String
    let colorHex: String

    // Возвращает URL файла из бандла приложения
    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }
}

// MARK: - Список треков
// Чтобы добавить свою песню:
// 1. Перетащи MP3/M4A файл в папку MusicPlayer в Xcode (поставь галку "Add to target")
// 2. Добавь новый Track() в этот массив
let sampleTracks: [Track] = [
    Track(title: "Midnight Glow",  artist: "Luna Waves",   fileName: "midnight_glow",  fileExtension: "mp3", emoji: "🌙", colorHex: "#6b21a8"),
    Track(title: "Neon Dreams",    artist: "Synthwave 84", fileName: "neon_dreams",    fileExtension: "mp3", emoji: "🌆", colorHex: "#1d4ed8"),
    Track(title: "Golden Hour",    artist: "The Drifters", fileName: "golden_hour",    fileExtension: "mp3", emoji: "🌅", colorHex: "#b45309"),
    Track(title: "Electric Soul",  artist: "Voltage",      fileName: "electric_soul",  fileExtension: "mp3", emoji: "⚡", colorHex: "#065f46"),
    Track(title: "Rainy Days",     artist: "Soft Palette", fileName: "rainy_days",     fileExtension: "mp3", emoji: "🌧", colorHex: "#1e3a5f"),
]
