//
//  Playlist.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import Foundation

struct Playlist: Codable {
    let description: String?
    let externalUrls: [String: String]?
    let id: String?
    let images: [APIImage]?
    let name: String
    let owner: User?

    enum CodingKeys: String, CodingKey {
        case description
        case externalUrls = "external_urls"
        case id
        case images
        case name
        case owner
    }
}

struct PlaylistDetails: Decodable {
    let description: String?
    let externalUrls: [String: String]?
    let id: String
    let images: [APIImage]?
    let name: String
    let owner: User?
    let tracks: PlaylistTracks?
    let items: PlaylistTracks?

    var audioTracks: [AudioTrack] {
        (items ?? tracks)?.items.compactMap(\.audioTrack) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case description
        case externalUrls = "external_urls"
        case id
        case images
        case name
        case owner
        case tracks
        case items
    }
}

struct FeaturedPlaylistModel: Codable {
    let message: String?
    let playlists: PlayListResponse
}

struct PlayListResponse: Codable {
    let href: String
    let items: [Playlist]
}

struct PlaylistTracks: Decodable {
    let items: [PlaylistItems]
}

struct PlaylistItems: Decodable {
    let audioTrack: AudioTrack?

    enum CodingKeys: String, CodingKey {
        case track
        case item
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        audioTrack = (try? container.decode(AudioTrack.self, forKey: .item))
            ?? (try? container.decode(AudioTrack.self, forKey: .track))
    }
}

