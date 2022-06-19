//
//  ErrorView.swift
//  Debiru
//
//  Created by Mike Polan on 6/13/21.
//

import SwiftUI

// MARK: - View

struct ErrorView: View {
    let type: ErrorType
    var additionalMessage: String?
    
    var body: some View {
        makeErrorView()
    }
    
    private func makeErrorView() -> some View {
        let iconName: String
        let message: String
        
        switch type {
        case .imageLoadFailed:
            iconName = "exclamationmark.circle"
            
            var text = "Failed to load image!"
            if let additionalMessage = additionalMessage {
                text = " \(additionalMessage)"
            }
            
            message = text
            
        case .threadDeleted:
            iconName = "exclamationmark.circle"
            message = "This thread has been deleted."
        }
        
        return VStack {
            Image(systemName: iconName)
                .imageScale(.large)
            
            Text(message)
                .padding(.top, 5)
        }
        .centered(.both)
    }
}

// MARK: - Extensions

extension ErrorView {
    enum ErrorType {
        case imageLoadFailed
        case threadDeleted
    }
}

// MARK: - Preview

struct ErrorView_Preview: PreviewProvider {
    static var previews: some View {
        ErrorView(type: .threadDeleted)
    }
}
