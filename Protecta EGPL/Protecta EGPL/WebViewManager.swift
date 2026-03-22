//
//  WebViewManager.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import Foundation
import UIKit
import WebKit

class WebViewManager: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    var webView: WKWebView!
    weak var viewController: UIViewController?

    func createWebView(in view: UIView) -> WKWebView {

        // ✅ Allow cookies
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        let contentController = WKUserContentController()
        contentController.add(self, name: "iosBridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        // ✅ Persistent storage
        config.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: view.bounds, configuration: config)

        webView.customUserAgent = "Protecta-iOS-App"
        webView.navigationDelegate = self

        view.addSubview(webView)

        return webView
    }

    // MARK: - Load URL

    func loadURL(_ urlString: String) {

        guard let url = URL(string: urlString) else { return }

        // 🔥 STEP 1: Restore cookies from UserDefaults
        restoreCookies()

        // 🔥 STEP 2: Sync to WKWebView
        syncCookiesToWebView()

        var request = URLRequest(url: url)

        // 🔥 STEP 3: Attach cookies manually
        if let cookies = HTTPCookieStorage.shared.cookies {
            let headers = HTTPCookie.requestHeaderFields(with: cookies)
            request.allHTTPHeaderFields = headers
        }

        webView.load(request)
    }

    // MARK: - Cookie Sync

    func syncCookiesToWebView() {

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

        let cookies = HTTPCookieStorage.shared.cookies ?? []

        for cookie in cookies {
            cookieStore.setCookie(cookie)
        }
    }

    func saveCookies() {

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in

            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            print("✅ Cookies saved to HTTPCookieStorage")

            // 🔥 Persist also
            self.persistCookies()
        }
    }

    // MARK: - UserDefaults Persistence

    func persistCookies() {

        var cookieArray: [[HTTPCookiePropertyKey: Any]] = []

        let cookies = HTTPCookieStorage.shared.cookies ?? []

        for cookie in cookies {

            if let properties = cookie.properties {

                // Optional: skip expired cookies
                if let expires = properties[.expires] as? Date,
                   expires < Date() {
                    continue
                }

                cookieArray.append(properties)
            }
        }

        UserDefaults.standard.set(cookieArray, forKey: "Protecta_SavedCookies")

        print("💾 Cookies persisted in UserDefaults")
    }

    func restoreCookies() {

        guard let cookieArray =
                UserDefaults.standard.array(forKey: "Protecta_SavedCookies")
                as? [[HTTPCookiePropertyKey: Any]] else {
            return
        }

        for properties in cookieArray {

            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }

        print("🔁 Cookies restored from UserDefaults")
    }

    // MARK: - Navigation Delegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString.lowercased()
        print("🌐 Loading URL:", urlString)

        // 🔥 1. Handle Documents (PDF / Images)
        if isDocument(urlString) {
            openDocumentViewer(url: url)
            decisionHandler(.cancel)
            return
        }

        // 🔥 2. Handle Invoice / Print Pages (YOUR ISSUE FIX)
        
        /*if isInvoicePage(urlString) {
            openDocumentViewer(url: url)
            decisionHandler(.cancel)
            return
        }*/

        // 🔥 3. Handle Popup / New Window (window.open)
        if navigationAction.targetFrame == nil {
            print("🪟 Popup detected")

            if isInvoicePage(urlString) || isDocument(urlString) {
                openDocumentViewer(url: url)
            } else {
                webView.load(navigationAction.request)
            }

            decisionHandler(.cancel)
            return
        }

        // ✅ Default allow
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        if let url = navigationAction.request.url {
            let urlString = url.absoluteString.lowercased()

            print("🪟 New window URL:", urlString)

            if isInvoicePage(urlString) || isDocument(urlString) {
                openDocumentViewer(url: url)
            } else {
                webView.load(URLRequest(url: url))
            }
        }

        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        saveCookies()
    }

    // MARK: - JS Bridge

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        if let body = message.body as? [String: Any],
           let action = body["action"] as? String {

            if action == "getToken" {
                let token = UserDefaults.standard.string(forKey: "Protecta_fcmToken") ?? ""
                webView.evaluateJavaScript("window.onReceiveToken('\(token)')")
            }

            if action == "openCamera" {
                NotificationCenter.default.post(name: .openCamera, object: nil)
            }
        }
    }

    // MARK: - Helpers

    private func isDocument(_ url: String) -> Bool {
        return url.hasSuffix(".pdf") ||
               url.hasSuffix(".jpg") ||
               url.hasSuffix(".jpeg") ||
               url.hasSuffix(".png") ||
               url.hasSuffix(".webp")
    }

    private func isInvoicePage(_ url: String) -> Bool {
        return url.contains("invoice") ||
               url.contains("invoices") ||
               url.contains("print") ||
               url.contains("download")
    }

    private func openDocumentViewer(url: URL) {

        let vc = DocumentViewerController()
        vc.url = url

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen

        viewController?.present(nav, animated: true)
    }
}
