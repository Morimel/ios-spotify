//
//  PlaylistViewController.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import UIKit

class LibraryView: UIViewController {

    public var selectionHandler: ((Playlist) -> Void)?
    private var playlists = [Playlist]()
    private let savedSongs = Playlist(description: "", externalUrls: nil, id: "", images: nil, name: "Saved songs", owner: nil)

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PlaylistsTableViewCell.self, forCellReuseIdentifier: PlaylistsTableViewCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        playlists = [savedSongs]
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshPlaylists), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPlaylists()
    }

    @objc private func refreshPlaylists() {
        Task {
            do {
                let playlists = try await SpotifyRepository.shared.getUserPlaylists()
                self.playlists = [savedSongs] + playlists.items
                self.tableView.reloadData()
                self.tableView.tableFooterView = nil
            } catch {
                let footer = UILabel()
                footer.text = error.localizedDescription
                footer.textColor = .secondaryLabel
                footer.textAlignment = .center
                footer.numberOfLines = 0
                footer.frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: 120)
                self.tableView.tableFooterView = footer
            }
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

extension LibraryView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaylistsTableViewCell.identifier,
                                                       for: indexPath) as? PlaylistsTableViewCell else {
            return UITableViewCell()
        }
        let model = playlists[indexPath.row]
        cell.configure(with: PlaylistsTableViewCellViewModel(
            imgUrl: URL(string: model.images?.first?.url ?? ""),
            name: model.name))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let playlist = playlists[indexPath.row]

        guard selectionHandler == nil else {
            selectionHandler?(playlist)
            dismiss(animated: true, completion: nil)
            return
        }

        let playListView = PlayListView(playlist: playlist)
        navigationController?.pushViewController(playListView, animated: true)
    }
}
