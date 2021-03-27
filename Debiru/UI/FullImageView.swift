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
        
        VStack {
            ScrollView {
                Image(nsImage: image)
            }
        }
        .frame(idealWidth: image.size.width, idealHeight: image.size.height)
    }
    
    private var image: NSImage {
        if let data = appState.openImageData,
           let image = NSImage(data: data){
            return image
        }
        
        return NSImage(systemSymbolName: "exclamationmark.circle", accessibilityDescription: nil) ?? NSImage()
    }
}

// MARK: - Preview

struct FullImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullImageView()
    }
}
