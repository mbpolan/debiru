//
//  AssetView.swift
//  Debiru
//
//  Created by Mike Polan on 7/25/24.
//

import SwiftUI
import WebKit

#if os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#else
typealias ViewRepresentable = NSViewRepresentable
#endif

// MARK: - View

/// A view that displays an asset.
struct AssetView: View {
    let asset: Asset
    private static let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        GeometryReader { geo in
            if let url = AssetView.dataProvider.getURL(for: asset, variant: .original) {
                switch asset.fileType {
                case .image:
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    
                case .animatedImage, .webm:
                    WebView(url: url, size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                Text("Invalid URL!")
            }
        }
        .navigationTitle("\(asset.filename)\(asset.extension)")
    }
}

/// A view that displays a WEBM video or animated content.
fileprivate struct WebView: ViewRepresentable {
    let url: URL
    let size: CGSize
    
    func makeUIView(context: Context) -> WKWebView {
        return makeView(context: context)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        return makeView(context: context)
    }
    
    func updateUIView(_ view: WKWebView, context: Context) {
        updateView(view, context: context)
    }
    
    func updateNSView(_ view: WKWebView, context: Context) {
        updateView(view, context: context)
    }
    
    private func makeView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: url))
        view.frame.size = size
        
        return view
    }
    
    private func updateView(_ view: WKWebView, context: Context) {
        view.frame.size = size
    }
}

// MARK: - Previews

#Preview("Image") {
    AssetView(asset: .init(id: 1594686780709,
                           boardId: "g",
                           width: 535,
                           height: 420,
                           thumbnailWidth: 535,
                           thumbnailHeight: 420,
                           filename: "sticky_btfo",
                           extension: ".png",
                           fileType: .image,
                           size: 1000))
    .frame(width: CGFloat(535), height: CGFloat(420))
}

#Preview("WEBM") {
    AssetView(asset: .init(id: 1721927258779274,
                           boardId: "wsg",
                           width: 140,
                           height: 250,
                           thumbnailWidth: 250,
                           thumbnailHeight: 140,
                           filename: "test",
                           extension: ".webm",
                           fileType: .webm,
                           size: 1000))
    .frame(width: CGFloat(500), height: CGFloat(500))
}
