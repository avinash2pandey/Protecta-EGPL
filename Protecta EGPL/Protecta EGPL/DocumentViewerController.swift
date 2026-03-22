//
//  DocumentViewerController.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 22/03/26.
//

import Foundation
import UIKit
import WebKit

class DocumentViewerController: UIViewController, WKNavigationDelegate {

    var url: URL!
    private var webView: WKWebView!
    private var spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Preview"

        setupWebView()
        setupNavigationBar()
        setupLoader()

        webView.load(URLRequest(url: url))
    }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()

            // ✅ SHARE SAME COOKIE STORE
            config.websiteDataStore = WKWebsiteDataStore.default()

            webView = WKWebView(frame: view.bounds, configuration: config)

            webView.navigationDelegate = self
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            view.addSubview(webView)
    }

    private func setupNavigationBar() {

        // ✅ Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        // ✅ Share button (safe for iPad)
        let shareItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )

        navigationItem.rightBarButtonItem = shareItem
    }

    private func setupLoader() {
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()
    }

    // MARK: - Actions

    @objc private func closeTapped() {

        // ✅ Save cookies before closing
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
            print("✅ Cookies synced from viewer")
        }

        dismiss(animated: true)
    }

    @objc private func shareTapped() {

        guard let url = url else { return }

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        // ✅ FIX: iPad crash (popover anchor)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(activityVC, animated: true)
    }

    // MARK: - WebView Delegate

    func webView(_ webView: WKWebView,
                 didStartProvisionalNavigation navigation: WKNavigation!) {
        spinner.startAnimating()
    }

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        spinner.stopAnimating()
        print("❌ Load failed:", error.localizedDescription)
    }
}
