//
//  AuthManager.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()

    private var refreshingToken = false

    private init() {}

    public var signInURL: URL? {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Constants.clientID),
            URLQueryItem(name: "scope", value: Constants.scopes.replacingOccurrences(of: "%20", with: " ")),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        return components?.url
    }
    var isSignedIn: Bool {
        return accessToken != nil
    }

    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }

    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }

    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }

    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return refreshToken != nil
        }
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300

        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }

    public func exchangeCodeForToken(
        code: String,
        completion: @escaping(Bool) -> Void) {
        // Get Token
            guard let url = URL(string: Constants.tokenAPIURL) else { return  }

            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
            ]
            var request = URLRequest(url: url)
            request.httpMethod  = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let basicToken = Constants.clientID+":"+Constants.clientSecret
            let data = basicToken.data(using: .utf8)
            guard let base64String = data?.base64EncodedString() else {
                print("Error: failure to get base64 ")
                completion(false)
                return
            }
            request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
            request.httpBody = components.query?.data(using: .utf8 )

           let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil,
                      let response = response as? HTTPURLResponse,
                      (200..<300).contains(response.statusCode) else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                do {
                    let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self.cacheToken(result: result)
                    DispatchQueue.main.async { completion(true) }
                } catch {
                    DispatchQueue.main.async { completion(false) }

                }
            }
            task.resume()

    }

    private var onRefreshBlocks = [((Bool) -> Void)]()
    ///  Supply valid token to be u   sed with Api calls
    public func withValidToken(completion: @escaping (String?) -> Void) {
        if shouldRefreshToken || refreshingToken {
            refreshIfNeeded { [weak self] success in
                completion(success ? self?.accessToken : nil)
            }
        } else {
            completion(accessToken)
        }
    }

    public func refreshIfNeeded(force: Bool = false, completion: ((Bool) -> Void)?) {

        guard !refreshingToken else {
            if let completion = completion {
                onRefreshBlocks.append(completion)
            }
            return
        }
        guard shouldRefreshToken || force else {
            completion?(true)
            return
        }
        guard let refreshToken = self.refreshToken else {
            completion?(false)
            return
        }

        // Refresh the Token
        guard let url = URL(string: Constants.tokenAPIURL) else { return  }

        refreshingToken = true
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        var request = URLRequest(url: url)
        request.httpMethod  = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Error: failure to get base64 on refresh Token ")
            refreshingToken = false
            completion?(false)
            return
        }
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpBody = components.query?.data(using: .utf8 )

       let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
           var tokenResponse: AuthResponse?
           if let data = data,
              error == nil,
              let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) {
               tokenResponse = try? JSONDecoder().decode(AuthResponse.self, from: data)
           }
           DispatchQueue.main.async {
               guard let self = self else { return }
               if let tokenResponse = tokenResponse {
                   self.cacheToken(result: tokenResponse)
               }
               self.refreshingToken = false
               let succeeded = tokenResponse != nil
               completion?(succeeded)
               self.onRefreshBlocks.forEach { $0(succeeded) }
               self.onRefreshBlocks.removeAll()
           }
       }
        task.resume()

    }

    public func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.accessToken, forKey: "access_token")
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expiresIn)),
                                       forKey: "expirationDate")

        if let refreshToken = result.refreshToken {
            UserDefaults.standard.setValue(refreshToken, forKey: "refresh_token")
        }

    }

    public func signout(completion: (Bool) -> Void) {
        UserDefaults.standard.setValue(nil, forKey: "access_token")
        UserDefaults.standard.setValue(nil, forKey: "expirationDate")
        UserDefaults.standard.setValue(nil, forKey: "refresh_token")
        completion(true)
    }

}
