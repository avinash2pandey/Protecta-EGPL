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

    func createWebView(in view: UIView) -> WKWebView {

        let contentController = WKUserContentController()
        contentController.add(self, name: "iosBridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self

        view.addSubview(webView)
        return webView
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        if let body = message.body as? [String: Any],
           let action = body["action"] as? String {

            if action == "getToken" {
                let token = UserDefaults.standard.string(forKey: "fcmToken") ?? ""
                webView.evaluateJavaScript("window.onReceiveToken('\(token)')")
            }

            if action == "openCamera" {
                NotificationCenter.default.post(name: .openCamera, object: nil)
            }
        }
    }
}
