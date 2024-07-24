//
//  DetailView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

struct DetailView: View {
    var body: some View {
        Group {
            Text("Select a board to view threads")
                .font(.subheadline)
                .foregroundStyle(.placeholder)
        }
    }
}

// MARK: - Previews

#Preview {
    DetailView()
}
