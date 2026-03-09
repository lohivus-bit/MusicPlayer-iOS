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
        
        // Load metadata from both asset and track
        let assetMetadata = asset.commonMetadata
        var allMetadata = assetMetadata
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            allMetadata += audioTrack.commonMetadata
        }

        // Extract title - try multiple formats
        var titleItems = AVMetadataItem.metadataItems(from: allMetadata, filteredByIdentifier: .commonIdentifierTitle)
        if titleItems.isEmpty {
            titleItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.id3MetadataKeyTitleDescription, keySpace: .id3)
        }
        if titleItems.isEmpty {
            titleItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.iTunesMetadataKeyTitle, keySpace: .iTunes)
        }
        let title = titleItems.first?.stringValue ?? url.deletingPathExtension().lastPathComponent

        // Extract artist - try multiple formats
        var artistItems = AVMetadataItem.metadataItems(from: allMetadata, filteredByIdentifier: .commonIdentifierArtist)
        if artistItems.isEmpty {
            artistItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.id3MetadataKeyLeadPerformer, keySpace: .id3)
        }
        if artistItems.isEmpty {
            artistItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.iTunesMetadataKeyArtist, keySpace: .iTunes)
        }
        let artist = artistItems.first?.stringValue ?? "Неизвестный исполнитель"

        // Extract album name - try multiple formats
        var albumItems = AVMetadataItem.metadataItems(from: allMetadata, filteredByIdentifier: .commonIdentifierAlbumName)
        if albumItems.isEmpty {
            albumItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.id3MetadataKeyAlbumTitle, keySpace: .id3)
        }
        if albumItems.isEmpty {
            albumItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.iTunesMetadataKeyAlbum, keySpace: .iTunes)
        }
        let albumName = albumItems.first?.stringValue ?? "Неизвестный альбом"

        // Extract artwork - try multiple formats and methods
        var artworkData: Data? = nil
        
        // Try common identifier first
        var artworkItems = AVMetadataItem.metadataItems(from: allMetadata, filteredByIdentifier: .commonIdentifierArtwork)
        if let artworkItem = artworkItems.first {
            if let data = artworkItem.dataValue {
                artworkData = data
            } else if let data = artworkItem.value as? Data {
                artworkData = data
            } else if let dict = artworkItem.value as? NSDictionary, let data = dict["data"] as? Data {
                artworkData = data
            }
        }
        
        // Try ID3 format
        if artworkData == nil {
            artworkItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.id3MetadataKeyAttachedPicture, keySpace: .id3)
            if let artworkItem = artworkItems.first {
                if let data = artworkItem.dataValue {
                    artworkData = data
                } else if let data = artworkItem.value as? Data {
                    artworkData = data
                }
            }
        }
        
        // Try iTunes format
        if artworkData == nil {
            artworkItems = AVMetadataItem.metadataItems(from: allMetadata, withKey: AVMetadataKey.iTunesMetadataKeyCoverArt, keySpace: .iTunes)
            if let artworkItem = artworkItems.first {
                if let data = artworkItem.dataValue {
                    artworkData = data
                } else if let data = artworkItem.value as? Data {
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
