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

        view.backgroundColor = .systemBackground

        // ✅ Link manager with VC (IMPORTANT for navigation/present)
        manager.viewController = self

        // ✅ Create WebView
        webView = manager.createWebView(in: self.view)

        // ✅ Load URL WITH cookie/session handling
        manager.loadURL(Constants.baseURL)

        setupObservers()
    }
    
    // MARK: - Observers

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
        
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handlePaymentCallback),
                    name: .paymentCallback,
                    object: nil)
    }

    // MARK: - Deep Link Handling

    @objc func openDeepLink(_ notification: Notification) {

        guard let urlString = notification.object as? String else { return }

        print("🔗 Deep Link:", urlString)

        // ✅ Use manager (IMPORTANT for cookies/session)
        manager.loadURL(urlString)
    }

    // MARK: - Payment Callback

        @objc func handlePaymentCallback(_ notification: Notification) {

            guard let url = notification.object as? URL else { return }

            print("✅ Payment Result:", url.absoluteString)

            // 🔥 Reload CRM or redirect page
            manager.loadURL(Constants.baseURL)
        }

    // MARK: - File Upload

    @objc func openFileChooser() {

        uploader.openChooser(from: self) { urls in
            print("📂 Selected files:", urls ?? [])

            // 👉 Optional: Send file info back to WebView via JS
            if let firstURL = urls?.first {
                let js = "window.onFileSelected('\(firstURL.absoluteString)')"
                self.webView.evaluateJavaScript(js)
            }
        }
    }

    // MARK: - Back Navigation (Android-like)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // ✅ Sync cookies again when returning from viewer
        manager.syncCookiesToWebView()
        
        // Enable swipe back gesture inside WebView
        webView.allowsBackForwardNavigationGestures = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // Optional: hardware back handling (if needed later)
    func handleBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
