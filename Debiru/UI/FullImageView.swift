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
    @ObservedObject private var viewModel: FullImageViewModel = FullImageViewModel()
    private let dataProvider: DataProvider
    
    init(_ dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        VStack {
            switch viewModel.state {
            case .error(let error):
                ErrorView(type: .imageLoadFailed, additionalMessage: error.localizedDescription)
                    .centered(.both)
            case .loading:
                Text("Loading")
                    .centered(.both)
                    .foregroundColor(.secondary)
            case .empty:
                Text("Nothing to see here")
                    .centered(.both)
                    .foregroundColor(Color(PFPlaceholderTextColor))
            case .done(let data):
                if let image = appState.openImageAsset {
                    if viewModel.scaleMode == .stretch {
                        StretchedImageView(
                            image: image,
                            data: data,
                            scale: viewModel.scale)
                    } else if viewModel.scaleMode == .aspectRatio {
                        AspectRatioImageView(
                            image: image,
                            data: data,
                            scale: viewModel.scale)
                    } else {
                        OriginalImageView(
                            image: image,
                            data: data,
                            scale: viewModel.scale)
                    }
                } else {
                    PFMakeImage(systemName: "exclamationmark.circle")
                }
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
        .task(handleLoadImage)
        .onDisappear {
            appState.openImageAsset = nil
            viewModel.state = .empty
        }
    }
    
    @Sendable
    private func handleLoadImage() async {
        do {
            if let asset = appState.openImageAsset {
                viewModel.state = .loading
                if let data = try await dataProvider.getImage(for: asset, variant: .original) {
                    viewModel.state = .done(data)
                } else {
                    viewModel.state = .error(ImageError("Failed to load image"))
                }
            } else {
                viewModel.state = .empty
            }
        } catch {
            viewModel.state = .error(ImageError(error.localizedDescription))
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
    let image: Asset
    let data: Data
    let scale: CGFloat
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ImageContainerView(image: image, data: data, resizable: false)
                .frame(width: CGFloat(image.width), height: CGFloat(image.height))
                .scaleEffect(scale)
                .centered(.both)
        }
    }
}

// MARK: - Stretched Image View

fileprivate struct StretchedImageView: View {
    let image: Asset
    let data: Data
    let scale: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ImageContainerView(image: image, data: data, resizable: true)
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
    let image: Asset
    let data: Data
    let scale: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ImageContainerView(image: image, data: data, resizable: true)
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
    let image: Asset
    let data: Data
    let resizable: Bool
    
    var body: some View {
        if image.extension.hasSuffix(".gif") {
            AnimatedImageView(
                data: data,
                frame: PFSize(width: image.width, height: image.height))
        } else {
            makeStaticImage()
        }
    }
    
    private func makeStaticImage() -> Image {
        var image: Image
        if let img = PFMakeImage(data: data) {
            image = img
        } else {
            image = PFMakeImage(systemName: "exclamationmark.circle")
        }
        
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
    @Published var state: ImageState = .loading
    
    enum ImageState {
        case empty
        case loading
        case done(Data)
        case error(ImageError)
    }
}

struct ImageError: Error {
    let message: String
    
    init (_ message: String) {
        self.message = message
    }
    
    var localizedDescription: String {
        message
    }
}

// MARK: - Preview

struct FullImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullImageView()
    }
}
