//
//  AssetView.swift
//  Debiru
//
//  Created by Mike Polan on 7/25/24.
//

import SwiftUI

// MARK: - View

/// A view that displays an asset.
struct AssetView: View {
    let asset: Asset
    private static let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        Group {
            switch asset.fileType {
            case .image:
                AsyncImage(url: AssetView.dataProvider.getURL(for: asset, variant: .original)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                
            case .animatedImage:
                Text("?")
                
            case .webm:
                Text("?")
            }
        }
        .navigationTitle("\(asset.filename)\(asset.extension)")
    }
}

// MARK: - Previews
#Preview {
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
}
