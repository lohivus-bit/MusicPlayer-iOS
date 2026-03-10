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
        let metadata = asset.commonMetadata
        
        // Extract title
        var title: String?
        for item in AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierTitle) {
            title = item.stringValue
            break
        }
        if title == nil {
            title = url.deletingPathExtension().lastPathComponent
        }

        // Extract artist
        var artist: String?
        for item in AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtist) {
            artist = item.stringValue
            break
        }
        if artist == nil {
            artist = "Неизвестный исполнитель"
        }

        // Extract album name
        var albumName: String?
        for item in AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierAlbumName) {
            albumName = item.stringValue
            break
        }
        if albumName == nil {
            albumName = "Неизвестный альбом"
        }

        // Extract artwork
        var artworkData: Data? = nil
        for item in AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork) {
            if let data = item.dataValue {
                artworkData = data
                break
            } else if let data = item.value as? Data {
                artworkData = data
                break
            }
        }

        // Get duration
        let duration = CMTimeGetSeconds(asset.duration)
        let validDuration = duration.isNaN || duration.isInfinite ? 0 : duration

        return Track(
            id: UUID(),
            title: title ?? url.deletingPathExtension().lastPathComponent,
            artist: artist ?? "Неизвестный исполнитель",
            albumName: albumName ?? "Неизвестный альбом",
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
