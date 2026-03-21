//
//  WebViewController.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    var webView: WKWebView!
    let manager = WebViewManager()
    let uploader = FileUploadHandler()

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = manager.createWebView(in: self.view)

        if let url = URL(string: Constants.baseURL) {
            webView.load(URLRequest(url: url))
        }

        setupObservers()
    }

    private func setupObservers() {

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openDeepLink),
            name: .openDeepLink,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openFileChooser),
            name: .openCamera,
            object: nil)
    }

    @objc func openDeepLink(_ notification: Notification) {
        if let urlString = notification.object as? String,
           let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }

    @objc func openFileChooser() {
        uploader.openChooser(from: self) { urls in
            print("Selected files:", urls ?? [])
        }
    }
}
