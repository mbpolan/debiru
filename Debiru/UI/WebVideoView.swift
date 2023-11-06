//
//  WebVideoView.swift
//  Debiru
//
//  Created by Mike Polan on 5/6/21.
//

import SwiftUI
import WebKit

// MARK: - View

#if os(macOS)

struct WebVideoView: NSViewRepresentable {
    @EnvironmentObject private var appState: AppState
    var dataProvider: DataProvider = FourChanDataProvider()
    
    func makeCoordinator() -> Coordinator {
        return WebVideoView.Coordinator()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        
        DispatchQueue.main.async {
            if let video = appState.openWebVideo,
               let url = dataProvider.getURL(for: video) {
                view.load(URLRequest(url: url))
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}

#elseif os(iOS)

struct WebVideoView: UIViewRepresentable {
    @EnvironmentObject private var appState: AppState
    var dataProvider: DataProvider = FourChanDataProvider()
    
    func makeCoordinator() -> Coordinator {
        return WebVideoView.Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        
        DispatchQueue.main.async {
            if let video = appState.openWebVideo,
               let url = dataProvider.getURL(for: video) {
                view.load(URLRequest(url: url))
            }
        }
        
        return view
    }
    
    func updateUIView(_ nsView: WKWebView, context: Context) {
    }
}

#endif

extension WebVideoView {
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print(error)
        }
    }
}

// MARK: - Preview

struct WebVideoView_Preview: PreviewProvider {
    static var previews: some View {
        WebVideoView()
    }
}
