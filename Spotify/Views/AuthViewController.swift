//
//  AuthViewController.swift
//  Spotify
//
//  Created by Salvador on 05/02/23.
//

import UIKit
import WebKit

class AuthViewController: UIViewController, WKNavigationDelegate {

    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }()

    public var completionHandler: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign In"
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        view.addSubview(webView)
        guard let url = AuthManager.shared.signInURL else { return  }
        webView.load(URLRequest(url: url))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              url.absoluteString.hasPrefix(Constants.redirectURI) else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        guard let code = query?.first(where: { $0.name == "code" })?.value else {
            navigationController?.popToRootViewController(animated: false)
            completionHandler?(false)
            return
        }
        webView.isHidden = true
        AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
            if !success {
                self?.navigationController?.popToRootViewController(animated: false)
            }
            self?.completionHandler?(success)
        }
    }
}
