//
//  PlaceholderView.swift
//  Debiru
//
//  Created by Mike Polan on 5/4/21.
//

import SwiftUI

// MARK: - View

struct PlaceholderView: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("Use ⇧⌘O to bring up quick search")
                .foregroundColor(Color(NSColor.placeholderTextColor))
        }
    }
}

// MARK: - Preview

struct PlaceholderView_Preview: PreviewProvider {
    static var previews: some View {
        PlaceholderView()
    }
}
