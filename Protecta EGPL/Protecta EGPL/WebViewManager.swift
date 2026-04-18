//
//  WebViewManager.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import Foundation
import UIKit
import WebKit

class WebViewManager: NSObject,WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate {

    var webView: WKWebView!
    weak var viewController: UIViewController?

    func createWebView(in view: UIView) -> WKWebView {

        // ✅ Allow cookies
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        let contentController = WKUserContentController()
        contentController.add(self, name: "iosBridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // ✅ Persistent storage
        config.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: view.bounds, configuration: config)
        

        //webView.customUserAgent = "Protecta-iOS-App"
//        webView.customUserAgent =
//        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile Safari/604.1"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic

        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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

        print("✅ webView navigationAction:")
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString.lowercased()
        print("🌐 Loading URL:", urlString)
        
        // Payment intent schemes 🔥 Razorpay / UPI
       /* if isPaymentIntent(urlString) {
            print("🪟 upi/intent detected")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }*/
        if handleUPIPayment(urlString, webView: webView) {
                decisionHandler(.cancel)
                return
            }


        // 🔥 1. Handle Documents (PDF / Images)
        if isDocument(urlString) {
            print("🪟 isDocument detected")
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
        print("🪟 Default allow")
        decisionHandler(.allow)
        /*
        // If the request is a non-http(s) schema, then have the UIApplication handle opening the request.
           if let url = navigationAction.request.url,
              !url.absoluteString.hasPrefix("http://"),
              !url.absoluteString.hasPrefix("https://"),
              UIApplication.shared.canOpenURL(url) {
               
               // Have UIApplication handle the url (sms:, tel:, mailto:, ...)
               UIApplication.shared.open(url, options: [:], completionHandler: nil)
               
               // Cancel the request (handled by UIApplication).
               decisionHandler(.cancel)
           }
           else {
               // Allow the request.
               decisionHandler(.allow)
           }
        */
       
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        print("✅ webView configuration:")
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString.lowercased()

            print("🪟 New window URL:", urlString)

            if handleUPIPayment(urlString, webView: webView) {
                return nil
            }
//            else if isPaymentIntent(urlString) {
//                openExternalPayment(url: url)
//            }
            else if isInvoicePage(urlString) || isDocument(urlString) {
                openDocumentViewer(url: url)
            } else {
                webView.load(URLRequest(url: url))
            }
        }

        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ webView didFinish:")
        saveCookies()
    }
    
    // MARK: - JavaScript Popup Support

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {

        let alert = UIAlertController(
            title: webView.url?.host ?? "Alert",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default) { _ in
            completionHandler()
        })

        viewController?.present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {

        let alert = UIAlertController(
            title: webView.url?.host ?? "Confirm",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel) { _ in
            completionHandler(false)
        })

        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default) { _ in
            completionHandler(true)
        })

        viewController?.present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {

        let alert = UIAlertController(
            title: webView.url?.host ?? "Input",
            message: prompt,
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.text = defaultText
        }

        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel) { _ in
            completionHandler(nil)
        })

        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })

        viewController?.present(alert, animated: true)
    }

    // MARK: - JS Bridge

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        print("✅ webView userContentController:")
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

    // MARK: - Payment Handling

        private func openExternalPayment(url: URL) {

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                openUPIChooser(url: url)
            }
        }
    
    // MARK: - UPI Chooser

    func openUPIChooser(url: URL) {

            guard let vc = viewController else { return }

            let alert = UIAlertController(
                title: "Pay using UPI",
                message: "Choose your app",
                preferredStyle: .actionSheet
            )

            let apps: [(String, String)] = [
                ("Google Pay", "tez://"),
                ("PhonePe", "phonepe://"),
                ("Paytm", "paytmmp://"),
                ("BHIM", "bhim://"),
                ("Amazon Pay", "amazonpay://"),
                ("Cred", "credpay://"),
                ("Freecharge", "freecharge://"),
                ("Mobikwik", "mobikwik://"),
                ("Airtel Thanks", "airtel://"),
                ("WhatsApp Pay", "whatsapp://")
            ]

            var hasApps = false

            for app in apps {

                if let appURL = URL(string: app.1),
                   UIApplication.shared.canOpenURL(appURL) {

                    hasApps = true

                    alert.addAction(UIAlertAction(title: app.0, style: .default) { _ in
                        UIApplication.shared.open(url)
                    })
                }
            }

            if !hasApps {
                alert.message = "No supported UPI apps found. Continue in browser."
            }

            alert.addAction(UIAlertAction(title: "Open in Browser",
                                          style: .default) { _ in
                UIApplication.shared.open(url)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let pop = alert.popoverPresentationController {
                pop.sourceView = vc.view
                pop.sourceRect = CGRect(
                    x: vc.view.bounds.midX,
                    y: vc.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                pop.permittedArrowDirections = []
            }

            vc.present(alert, animated: true)
        }

    
    // MARK: - Helpers

    private func isPaymentIntent(_ url: String) -> Bool {

            return url.starts(with: "upi://") ||
                   url.starts(with: "intent://") ||
                   url.starts(with: "tez://") ||
                   url.starts(with: "phonepe://") ||
                   url.starts(with: "paytmmp://") ||
                   url.starts(with: "paytm://") ||
                   url.starts(with: "gpay://") ||
                   url.starts(with: "bhim://") ||
                   url.starts(with: "credpay://") ||
                   url.starts(with: "amazonpay://") ||
                   url.starts(with: "mobikwik://") ||
                   url.starts(with: "whatsapp://")
        }
    
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
    
    private func handleUPIPayment(_ url: String, webView: WKWebView) -> Bool {

        let lower = url.lowercased()

        // Direct schemes
        if lower.hasPrefix("upi://") ||
           lower.hasPrefix("gpay://") ||
           lower.hasPrefix("phonepe://") ||
           lower.hasPrefix("paytmmp://") ||
           lower.hasPrefix("tez://") {

            if let finalURL = URL(string: url) {
                UIApplication.shared.open(finalURL)
                return true
            }
        }

        // Android intent:// support
        if lower.hasPrefix("intent://") {
            return handleIntentURL(url, webView: webView)
        }

        return false
    }
    
    private func handleIntentURL(_ url: String, webView: WKWebView) -> Bool {

        // Example intent://upi/pay?...#Intent;scheme=upi;package=...
        
        // 1. Extract browser fallback
        if let fallback = extractBetween(
            source: url,
            start: "S.browser_fallback_url=",
            end: ";"
        ) {
            if let decoded = fallback.removingPercentEncoding,
               let fallbackURL = URL(string: decoded) {

                webView.load(URLRequest(url: fallbackURL))
                return true
            }
        }

        // 2. Convert intent:// → upi://
        if let range = url.range(of: "#Intent") {

            let base = String(url[..<range.lowerBound])

            let converted = base.replacingOccurrences(
                of: "intent://",
                with: "upi://"
            )

            if let finalURL = URL(string: converted) {
                UIApplication.shared.open(finalURL)
                return true
            }
        }

        return false
    }
    
    private func extractBetween(source: String,
                                start: String,
                                end: String) -> String? {

        guard let startRange = source.range(of: start) else { return nil }

        let substring = source[startRange.upperBound...]

        guard let endRange = substring.range(of: end) else {
            return String(substring)
        }

        return String(substring[..<endRange.lowerBound])
    }
}
