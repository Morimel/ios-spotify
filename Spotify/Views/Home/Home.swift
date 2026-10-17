//
//  NewHome.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import UIKit

enum SectionType {
    case topItems(viewModel: [ItemViewModel])
    case newReleases(viewModel: [ItemViewModel])
    case topSongs(viewModel: [ItemViewModel])
    case topArtists(viewModel: [ItemViewModel])
    case userPlaylist(viewModel: [ItemViewModel])
    case featuredPlaylists(viewModel: [ItemViewModel])
    case recommended(viewModel: [ItemViewModel])

    var count: Int {
        switch self {
        case .topItems(let viewModel):
            return viewModel.count
        case .newReleases(let viewModel):
            return viewModel.count
        case .topSongs(let viewModel):
            return viewModel.count
        case .topArtists(let viewModel):
            return viewModel.count
        case .userPlaylist(let viewModel):
            return viewModel.count
        case .featuredPlaylists(let viewModel):
            return viewModel.count
        case .recommended(let viewModel):
            return viewModel.count
        }
    }

    var title: String {
        switch self {
        case .topItems:
            return "Your top songs"
        case .newReleases:
            return "New Releases"
        case .topSongs:
            return "Your top songs"
        case .topArtists:
            return "Your top artists"
        case .userPlaylist:
            return "Your playlists"
        case .featuredPlaylists:
            return "Feautered playlists"
        case .recommended:
            return "Saved songs"
        }
    }
}

class Home: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    private var sections: [SectionType] = []
    var newReleases: [Album] = []
    var topSongs: [AudioTrack] = []
    var topArtist: [Artist] = []
    var recommended: [AudioTrack] = []
    var userPlaylists: [Playlist] = []
    var featuredPlaylists: [Playlist] = []

    private func fetchResult<T>(_ operation: () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    private func failure<T>(from result: Result<T, Error>) -> Error? {
        if case .failure(let error) = result { return error }
        return nil
    }

    init() {
        super.init(collectionViewLayout:
                    UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection? in
            return Home.createSectionLayout(section: sectionIndex)
        })
    }

    static func createSectionLayout(section: Int) -> NSCollectionLayoutSection {

        let supplymentryViews = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(60)),
                elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing)
        ]

        switch section {
        case 0:
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)))

            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(180)),
                subitem: item,
                count: 2)

            horizontalGroup.interItemSpacing = .fixed(10)

            let verticalGroup = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(180)),
                subitem: horizontalGroup,
                count: 3)

            verticalGroup.interItemSpacing = .fixed(10)

            // Section
            let section = NSCollectionLayoutSection(group: verticalGroup)
            section.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            section.orthogonalScrollingBehavior = .none
            section.boundarySupplementaryItems = supplymentryViews
            return section
        default:
            // Item
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .fractionalHeight(1)))

            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 10)

            let horizontalGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.4),
                    heightDimension: .absolute(180)),
                subitem: item,
                count: 1 )

            // Section
            let section = NSCollectionLayoutSection(group: horizontalGroup)
            section.orthogonalScrollingBehavior = .continuous
            section.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            section.boundarySupplementaryItems = supplymentryViews
            return section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadData() async {
        async let topTracksRequest = fetchResult { try await SpotifyRepository.shared.getUserTopTracks(limit: 6) }
        async let topArtistsRequest = fetchResult { try await SpotifyRepository.shared.getUserTopArtists(limit: 8) }
        async let playlistsRequest = fetchResult { try await SpotifyRepository.shared.getUserPlaylists() }
        async let savedTracksRequest = fetchResult { try await SpotifyRepository.shared.getUserTracks() }

        let topTracksResult = await topTracksRequest
        let topArtistsResult = await topArtistsRequest
        let playlistsResult = await playlistsRequest
        let savedTracksResult = await savedTracksRequest

        topSongs = (try? topTracksResult.get()) ?? []
        topArtist = (try? topArtistsResult.get()) ?? []
        userPlaylists = (try? playlistsResult.get())?.items ?? []
        let savedTracks = ((try? savedTracksResult.get()) ?? []).map(\.track)
        let loadError = [failure(from: topTracksResult), failure(from: topArtistsResult),
                         failure(from: playlistsResult), failure(from: savedTracksResult)]
            .compactMap { $0 }.first
        if topSongs.isEmpty {
            topSongs = Array(savedTracks.prefix(6))
        }

        sections = []
        if !topSongs.isEmpty {
            sections.append(.topItems(viewModel: self.topSongs.map({
                return ItemViewModel(
                    name: $0.name, artistName: $0.artists.first?.name ?? "-",
                    cover: URL(string: $0.album?.images.first?.url ?? "")
                )
            })))
        }
        if !topArtist.isEmpty {
            sections.append(.topArtists(viewModel: self.topArtist.map({
            return ItemViewModel(
                name: $0.name,
                artistName: $0.name,
                cover: URL(string: $0.images?.first?.url ?? "")
            )
            })))
        }
        if !userPlaylists.isEmpty {
            sections.append(.userPlaylist(viewModel: self.userPlaylists.map({
            return ItemViewModel(
                name: $0.name,
                artistName: $0.name,
                cover: URL(string: $0.images?.first?.url ?? ""))
            })))
        }
        if !savedTracks.isEmpty {
            sections.append(.recommended(viewModel: savedTracks.map({
            return ItemViewModel(name: $0.name,
                                 artistName: $0.artists.first?.name ?? "-",
                                 cover: URL(string: $0.album?.images.first?.url ?? ""))
            })))
            recommended = savedTracks
        }
        let emptyLabel = UILabel()
        emptyLabel.text = loadError?.localizedDescription ?? "Your Spotify library is empty. Pull down to refresh."
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        collectionView.backgroundView = topSongs.isEmpty && topArtist.isEmpty && userPlaylists.isEmpty && savedTracks.isEmpty ? emptyLabel : nil
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.register(HomeItemCell.self, forCellWithReuseIdentifier: HomeItemCell.id)
        collectionView?.register(TopItemCell.self, forCellWithReuseIdentifier: TopItemCell.id)

        collectionView?.register(TitleHeaderView.self,
                                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                 withReuseIdentifier: TitleHeaderView.identifier)

        Task {
            await loadData()
        }

        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)

        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }

    @objc private func refreshData() {
        Task {
            await loadData()
            collectionView.refreshControl?.endRefreshing()
        }
    }


    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = sections[indexPath.section]

        switch sectionType {
        case .topItems(let items):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopItemCell.id,
                                                                for: indexPath) as? TopItemCell else {
                fatalError("Failed to dequeue TopItemCell")
            }
            cell.track = items[indexPath.row]
            cell.setup()
            return cell

        case .newReleases(let items),
             .topSongs(let items),
             .userPlaylist(let items),
             .featuredPlaylists(let items),
             .recommended(let items):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeItemCell.id,
                                                                for: indexPath) as? HomeItemCell else {
                fatalError("Failed to dequeue HomeItemCell")
            }
            cell.track = items[indexPath.row]
            cell.setup()
            return cell

        case .topArtists(let items):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeItemCell.id,
                                                                for: indexPath) as? HomeItemCell else {
                fatalError("Failed to dequeue HomeItemCell")
            }
            cell.track = items[indexPath.row]
            cell.setup(roundImage: true) // Если нужно показать круглое изображение
            return cell
        }
    }

    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let section = sections[indexPath.section]

        switch section {
        case .topItems:
            let song = topSongs[indexPath.row]
            AudioManager.sharedInstance.playTrack(track: song)
        case .newReleases:
            let album = newReleases[indexPath.row]
            let albumView = AlbumView(album: album)
            self.navigationController?.pushViewController(albumView, animated: false)
        case .topSongs:
            let song = topSongs[indexPath.row]
            AudioManager.sharedInstance.playTrack(track: song)
        case .topArtists:
            let artist = topArtist[indexPath.row]
            let artistView = ArtistView(artist: artist)
            self.navigationController?.pushViewController(artistView, animated: true)
        case .userPlaylist:
            let playlist = userPlaylists[indexPath.row]
            let playlistView = PlayListView(playlist: playlist)
            self.navigationController?.pushViewController(playlistView, animated: false)
        case .featuredPlaylists:
            let playlist = featuredPlaylists[indexPath.row]
            let playListView = PlayListView(playlist: playlist)
            self.navigationController?.pushViewController(playListView, animated: false)
        case .recommended:
            let song = recommended[indexPath.row]
            AudioManager.sharedInstance.playTrack(track: song)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let type = sections[section]
        return type.count
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {

        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TitleHeaderView.identifier,
            for: indexPath) as? TitleHeaderView,
              kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let title = sections[indexPath.section].title
        header.configure(with: title)
        return header
    }
}
