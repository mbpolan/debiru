//
//  LandingView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

/// A view that acts as a placeholder when no activity is performed in the app.
struct LandingView: View {
    var body: some View {
        Text("Select a board to view threads")
            .font(.subheadline)
            .foregroundStyle(.placeholder)
    }
}

// MARK: - Previews

#Preview {
    LandingView()
        .frame(width: 640, height: 480)
}
