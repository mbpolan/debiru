//
//  HoverTextViewModifier.swift
//  Debiru
//
//  Created by Mike Polan on 3/29/21.
//

import SwiftUI

// MARK: - View Modifier

struct HoverTextViewModifier: ViewModifier {
    @State private var hovered: Bool = false
    
    let backgroundColor: Color
    let foregroundColor: Color
    
    func body(content: Content) -> some View {
        return content
            .foregroundColor(hovered ? .primary : foregroundColor)
            .background(hovered ? backgroundColor : Color.clear)
            .clipShape(Capsule())
            .onHover { hovered in
                self.hovered = hovered
            }
    }
}

// MARK: - Extensions

extension View {
    func hoverEffect(backgroundColor: Color = Color(.systemBlue),
                     foregroundColor: Color = Color(PFTextColor)) -> some View {
        
        self.modifier(HoverTextViewModifier(
                        backgroundColor: backgroundColor,
                        foregroundColor: foregroundColor))
    }
}

// MARK: - Preview

struct HoverText_Previews: PreviewProvider {
    static var previews: some View {
        Text("This is some text")
            .hoverEffect(
                backgroundColor: Color(.systemBlue),
                foregroundColor: Color(.black))
    }
}
