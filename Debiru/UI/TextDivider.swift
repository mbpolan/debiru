//
//  TextDivider.swift
//  Debiru
//
//  Created by Mike Polan on 4/10/21.
//

import SwiftUI

// MARK: - View

struct TextDivider: View {
    private let text: String
    private let color: Color
    private let height: CGFloat
    
    init(_ text: String, color: Color, height: CGFloat = 1.0) {
        self.text = text
        self.color = color
        self.height = height
    }
    
    var body: some View {
        HStack {
            makeLine()
            Text(text)
                .foregroundColor(color)
            makeLine()
        }
    }
    
    private func makeLine() -> some View {
        VStack {
            color.frame(height: height)
        }
    }
}

// MARK: - Previews

struct TextDivider_Previews: PreviewProvider {
    static var previews: some View {
        TextDivider("Some text", color: .red)
    }
}
