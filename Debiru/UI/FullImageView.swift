//
//  FullImageView.swift
//  Debiru
//
//  Created by Mike Polan on 3/27/21.
//

import SwiftUI

// MARK: - View

struct FullImageView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: FullImageViewModel = FullImageViewModel()
    
    var body: some View {
        let image = self.image
        
        VStack {
            if viewModel.scaleMode == .stretch {
                StretchedImageView(image: image)
            } else if viewModel.scaleMode == .aspectRatio {
                AspectRatioImageView(image: image)
            } else {
                OriginalImageView(image: image)
            }
        }
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
        .edgesIgnoringSafeArea(.top)
    }
    
    private var image: NSImage {
        if let data = appState.openImageData,
           let image = NSImage(data: data){
            return image
        }
        
        return NSImage(
            systemSymbolName: "exclamationmark.circle",
            accessibilityDescription: nil) ?? NSImage()
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
    let image: NSImage
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(nsImage: image)
                .centered(.both)
        }
    }
}

// MARK: - Stretched Image View

fileprivate struct StretchedImageView: View {
    let image: NSImage
    
    var body: some View {
        GeometryReader { geo in
            Image(nsImage: image)
                .resizable()
                .frame(
                    width: geo.size.width,
                    height: geo.size.height)
                .centered(.both)
        }
    }
}

// MARK: - Aspect Ratio Image View

fileprivate struct AspectRatioImageView: View {
    let image: NSImage
    
    var body: some View {
        GeometryReader { geo in
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height)
                .centered(.both)
        }
    }
}

// MARK: - View Model

class FullImageViewModel: ObservableObject {
    @Published var scaleMode: ScaleMode = .aspectRatio
    
    enum ScaleMode {
        case original
        case stretch
        case aspectRatio
    }
}

// MARK: - Preview

struct FullImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullImageView()
    }
}
