//
//  AssetView.swift
//  Debiru
//
//  Created by Mike Polan on 5/5/21.
//

import SwiftUI

// MARK: - View

struct AssetView: View {
    let asset: Asset
    let saveLocation: URL
    let bounds: CGSize?
    let onOpen: (_: Data, _: Asset) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .center) {
                WebImage(viewableAsset,
                         saveLocation: saveLocation,
                         bounds: bounds,
                         onOpen: { onOpen($0, asset)})
                
                // show a play icon indicator for videos
                if asset.fileType == .webm {
                    Image(systemName: "play.circle")
                        .font(.system(size: 32, weight: .medium))
                }
            }
            
            Spacer()
        }
    }
    
    private var viewableAsset: Asset {
        // webm videos are not supported by avfoundation, so instead show a thumbnail
        // image in its place
        if asset.fileType == .webm {
            return Asset(
                id: asset.id,
                boardId: asset.boardId,
                width: asset.width,
                height: asset.height,
                thumbnailWidth: asset.thumbnailWidth,
                thumbnailHeight: asset.thumbnailHeight,
                filename: asset.filename,
                extension: "s.jpg", // thumbnails use the "s.jpg" suffix
                fileType: asset.fileType)
        }
        
        return asset
    }
}

// MARK: - Preview

struct AssetView_Preview: PreviewProvider {
    static var previews: some View {
        AssetView(
            asset: Asset(
                id: 123,
                boardId: "f",
                width: 32,
                height: 32,
                thumbnailWidth: 16,
                thumbnailHeight: 16,
                filename: "lol",
                extension: ".jpg",
                fileType: .image),
            saveLocation: URL(string: "/Users")!,
            bounds: nil,
            onOpen: { _, _ in })
    }
}
