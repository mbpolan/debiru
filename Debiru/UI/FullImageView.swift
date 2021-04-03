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
    
    var body: some View {
        let image = self.image
        
        ScrollView {
            Image(nsImage: image)
        }
        .edgesIgnoringSafeArea(.top)
        .frame(
            idealWidth: min(image.size.width, NSScreen.main?.frame.maxX ?? .infinity),
            idealHeight: min(image.size.height, NSScreen.main?.frame.maxY ?? .infinity))
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
}

// MARK: - Preview

struct FullImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullImageView()
    }
}
