//
//  Search.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import Foundation
import UIKit

class SearchView: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {

    let searchController: UISearchController = {
        let results = SearchResultViewController()
        let searchController = UISearchController(searchResultsController: results)
        searchController.searchBar.placeholder = "Songs, Artist, Albums"
        searchController.searchBar.searchBarStyle = .minimal
        return searchController
    }()

    private let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { _, _ -> NSCollectionLayoutSection in
            // item
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(
                top: 2, leading: 7, bottom: 2, trailing: 7)
            // group
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150)), subitem: item, count: 2 )
            group.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
            // section
            return NSCollectionLayoutSection(group: group)
        }))

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        return collectionView
    }()

    private let suggestions = ["Pop", "Hip-Hop", "Rock", "Jazz", "Electronic", "R&B", "Indie", "Classical"]
    private var searchTask: Task<Void, Never>?

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    private func performSearch() {
        guard let resultsController = searchController.searchResultsController as? SearchResultViewController,
              let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            return
        }
        resultsController.delegate = self
        searchTask?.cancel()
        searchTask = Task {
            do {
                let results = try await SpotifyRepository.shared.search(with: query)
                guard !Task.isCancelled else { return }
                resultsController.update(with: results)
            } catch {
                guard !Task.isCancelled else { return }
                resultsController.showError(error)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        navigationItem.searchController = searchController
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)

        collectionView.register(CategoriesCollectionViewCell.self,
                                forCellWithReuseIdentifier: CategoriesCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }
}

extension SearchView: UICollectionViewDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoriesCollectionViewCell.identifier,
            for: indexPath) as? CategoriesCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: CategoriesCellViewModel(title: suggestions[indexPath.row], imageUrl: nil))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        searchController.isActive = true
        searchController.searchBar.text = suggestions[indexPath.row]
        performSearch()
    }


    func updateSearchResults(for searchController: UISearchController) {
        searchTask?.cancel()
        guard let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            (searchController.searchResultsController as? SearchResultViewController)?.clear()
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            performSearch()
        }
    }
}

extension SearchView: SearchResultViewControllerDelegate {

    func didTapResult(_ result: SearchResults) {
        searchController.isActive = false
        switch result {
        case .artist(let model):
            let artistView = ArtistView(artist: model)
            navigationController?.pushViewController(artistView, animated: true)
        case .album(let model):
            let albumView = AlbumView(album: model)
            navigationController?.pushViewController(albumView, animated: true )
        case .track(let model):
            AudioManager.sharedInstance.playTrack(track: model)
        case .playlist(let model):
            let playListView = PlayListView(playlist: model)
            playListView.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(playListView, animated: true)
        }
    }
}
