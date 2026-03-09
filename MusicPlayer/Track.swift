import Foundation
import AVFoundation
import UIKit

struct Track: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let albumName: String
    let duration: TimeInterval
    let artworkData: Data?
    let fileURL: URL

    // Equatable conformance by id
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Artwork as UIImage
    var artworkImage: UIImage? {
        guard let data = artworkData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Create Track from file URL by extracting ID3 metadata
    static func fromFile(url: URL) -> Track? {
        let asset = AVURLAsset(url: url)
        let metadata = asset.metadata

        // Extract title
        let titleItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierTitle)
        let title = titleItems.first?.stringValue ?? url.deletingPathExtension().lastPathComponent

        // Extract artist
        let artistItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtist)
        let artist = artistItems.first?.stringValue ?? "Неизвестный исполнитель"

        // Extract album name
        let albumItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierAlbumName)
        let albumName = albumItems.first?.stringValue ?? "Неизвестный альбом"

        // Extract artwork
        var artworkData: Data? = nil
        let artworkItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork)
        if let artworkItem = artworkItems.first {
            if let data = artworkItem.dataValue {
                artworkData = data
            } else if let value = artworkItem.value {
                // Some formats store artwork as NSData wrapped in value
                if let data = value as? Data {
                    artworkData = data
                }
            }
        }

        // Get duration
        let duration = CMTimeGetSeconds(asset.duration)
        let validDuration = duration.isNaN || duration.isInfinite ? 0 : duration

        return Track(
            id: UUID(),
            title: title,
            artist: artist,
            albumName: albumName,
            duration: validDuration,
            artworkData: artworkData,
            fileURL: url
        )
    }

    // MARK: - Formatted duration string
    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
