//
//  CaptchaView.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import SwiftUI
import WebKit

// MARK: - View

struct CaptchaView: NSViewRepresentable {
    private let captchaHTML = """
<html>
  <head>
    <script src="https://www.google.com/recaptcha/api.js" async defer></script>
    <script>
      function onCaptchaResponse(response) {
        window.webkit.messageHandlers.captcha.postMessage(response);
      }
    </script>
  </head>
  <body>
    <div class="g-recaptcha"
         data-theme="dark"
         data-size="normal"
         data-callback="onCaptchaResponse"
         data-sitekey="$SITE_KEY" />
    </form>
  </body>
</html>
"""
    
    private let handler: CaptchaMessageHandler
    
    init(onCaptchaResponse: @escaping(_: String) -> Void) {
        self.handler = CaptchaMessageHandler(onCaptchaResponse: onCaptchaResponse)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.userContentController.add(handler, name: "captcha")
        
        let view = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 75),
            configuration: config)
        view.setValue(false, forKey: "drawsBackground")
        view.loadHTMLString(template, baseURL: URL(string: "https://boards.4chan.org")!)
        
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
    
    private var template: String {
        return captchaHTML.replacingOccurrences(of: "$SITE_KEY", with: Parameters.shared.siteKey)
    }
}

// MARK: - Message Handler

class CaptchaMessageHandler: NSObject, WKScriptMessageHandler {
    private let onCaptchaResponse: (_: String) -> Void
    
    init(onCaptchaResponse: @escaping(_: String) -> Void) {
        self.onCaptchaResponse = onCaptchaResponse
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // the message body contains the captcha response token
        if let token = message.body as? String {
            onCaptchaResponse(token)
        }
    }
}
