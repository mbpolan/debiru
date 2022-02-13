//
//  AssetView.swift
//  Debiru
//
//  Created by Mike Polan on 5/5/21.
//

import SwiftUI

// MARK: - View

struct AssetView: View {
    private static let byteFormatter = { () -> ByteCountFormatter in
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        return formatter
    }()
    
    private let spoilerBlur: CGFloat = 10.0
    private let spoilerBlurDuration: Double = 0.1
    
    @StateObject private var viewModel: AssetViewModel = AssetViewModel()
    let asset: Asset
    let saveLocation: URL
    let spoilered: Bool
    let bounds: CGSize?
    let onOpen: (_: Data?, _: Asset) -> Void
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                WebImage(viewableAsset,
                         saveLocation: saveLocation,
                         bounds: bounds,
                         onOpen: { onOpen($0, asset)})
                    .blur(radius: viewModel.blur)
                
                // show a play icon indicator for videos
                if asset.fileType == .webm {
                    Image(systemName: "play.circle")
                        .font(.system(size: 32, weight: .medium))
                }
            }
            
            Text("\(asset.filename)\(asset.extension)")
                .foregroundColor(Color(NSColor.secondaryLabelColor))
                .truncationMode(.tail)
                .lineLimit(1)
                .frame(maxWidth: bounds?.width ?? .infinity)
            
            Text("\(AssetView.byteFormatter.string(fromByteCount: asset.size))")
                .foregroundColor(Color(NSColor.secondaryLabelColor))
            
            Spacer()
        }
        .onHover { hovering in
            withAnimation(.linear(duration: spoilerBlurDuration)) {
                viewModel.blur = hovering ? .zero : spoilered ? spoilerBlur : .zero
            }
        }
        .onAppear {
            viewModel.blur = spoilered ? spoilerBlur : .zero
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
                fileType: asset.fileType,
                size: 64)
        }
        
        return asset
    }
}

class AssetViewModel: ObservableObject {
    @Published var blur: CGFloat = 0.0
}

// MARK: - Preview

struct AssetView_Preview: PreviewProvider {
    static var previews: some View {
        AssetView(
            asset: Asset(
                id: 1594686780709,
                boardId: "g",
                width: 128,
                height: 128,
                thumbnailWidth: 16,
                thumbnailHeight: 16,
                filename: "lol",
                extension: ".png",
                fileType: .image,
                size: 64),
            saveLocation: URL(string: "/Users")!,
            spoilered: true,
            bounds: CGSize(width: 128, height: 128),
            onOpen: { _, _ in })
            .frame(width: 200, height: 200)
    }
}
