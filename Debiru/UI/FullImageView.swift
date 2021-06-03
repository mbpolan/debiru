//
//  FullImageView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

enum ImageScaleMode {
    case original
    case stretch
    case aspectRatio
}

struct FullImageView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: FullImageViewModel = FullImageViewModel()
    
    var body: some View {
        VStack {
            if let image = appState.openImageData {
                if viewModel.scaleMode == .stretch {
                    StretchedImageView(
                        image: image,
                        scale: viewModel.scale)
                } else if viewModel.scaleMode == .aspectRatio {
                    AspectRatioImageView(
                        image: image,
                        scale: viewModel.scale)
                } else {
                    OriginalImageView(
                        image: image,
                        scale: viewModel.scale)
                }
            } else {
                Image(nsImage: NSImage(
                        systemSymbolName: "exclamationmark.circle",
                        accessibilityDescription: nil) ?? NSImage())
            }
        }
        .frame(minWidth: 100, minHeight: 100)
        .edgesIgnoringSafeArea(.top)
        .toolbar {
            Button(action: handleOriginalMode) {
                Image(systemName: viewModel.scaleMode == .original
                        ? "photo.fill"
                        : "photo")
            }
            .help("Show image in its original size")
            
            Button(action: handleAspectRatioMode) {
                Image(systemName: viewModel.scaleMode == .aspectRatio
                        ? "arrow.up.right.circle.fill"
                        : "arrow.up.right.circle")
            }
            .help("Show image resized with respect to its aspect ratio")
            
            Button(action: handleStretchMode) {
                Image(systemName: viewModel.scaleMode == .stretch
                        ? "arrow.up.left.and.arrow.down.right.circle.fill"
                        : "arrow.up.left.and.arrow.down.right.circle")
            }
            .help("Show image stretched to fit the window")
        }
        .onImageMode { viewModel.scaleMode = $0 }
        .onImageZoom { handleImageZoom($0) }
        .onDisappear {
            appState.openImageData = nil
        }
    }
    
    private func handleImageZoom(_ zoom: ImageZoomNotification) {
        switch zoom {
        case .zoomIn:
            viewModel.scale *= 1.25
        case .zoomOut:
            viewModel.scale /= 1.25
        case .zoomNormal:
            viewModel.scale = 1.0
        }
    }
    
    private func handleOriginalMode() {
        viewModel.scaleMode = .original
    }
    
    private func handleStretchMode() {
        viewModel.scaleMode = .stretch
    }
    
    private func handleAspectRatioMode() {
        viewModel.scaleMode = .aspectRatio
    }
}

// MARK: - Original Image View

fileprivate struct OriginalImageView: View {
    let image: DownloadedAsset
    let scale: CGFloat
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ImageContainerView(image: image, resizable: false)
                .frame(width: CGFloat(image.asset.width), height: CGFloat(image.asset.height))
                .scaleEffect(scale)
                .centered(.both)
        }
    }
}

// MARK: - Stretched Image View

fileprivate struct StretchedImageView: View {
    let image: DownloadedAsset
    let scale: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ImageContainerView(image: image, resizable: true)
                .scaleEffect(scale)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height)
                .centered(.both)
        }
    }
}

// MARK: - Aspect Ratio Image View

fileprivate struct AspectRatioImageView: View {
    let image: DownloadedAsset
    let scale: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ImageContainerView(image: image, resizable: true)
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height)
                .centered(.both)
        }
    }
}

fileprivate struct ImageContainerView: View {
    let image: DownloadedAsset
    let resizable: Bool
    
    var body: some View {
        if image.asset.extension.hasSuffix(".gif") {
            AnimatedImageView(
                data: image.data,
                frame: NSSize(width: image.asset.width, height: image.asset.height))
        } else {
            makeStaticImage()
        }
    }
    
    private func makeStaticImage() -> Image {
        var nsImage: NSImage
        if let img = NSImage(data: image.data) {
            nsImage = img
        } else {
            nsImage = NSImage(
                systemSymbolName: "exclamationmark.circle",
                accessibilityDescription: nil) ?? NSImage()
        }
        
        var image = Image(nsImage: nsImage)
        if resizable {
            image = image.resizable()
        }
        
        return image
    }
}

// MARK: - View Model

class FullImageViewModel: ObservableObject {
    @Published var scaleMode: ImageScaleMode = .aspectRatio
    @Published var scale: CGFloat = 1.0
}

// MARK: - Preview

struct FullImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullImageView()
    }
}
