//
//  CenteredViewModifier.swift
//  Debiru
//
//  Created by Mike Polan on 4/24/21.
//

import SwiftUI

// MARK: - View Modifier

struct CenteredViewModifier: ViewModifier {
    let axis: ViewAlignmentAxis
    
    func body(content: Content) -> some View {
        Group {
            if axis == .vertical {
                VStack {
                    Spacer()
                    content
                    Spacer()
                }
            } else if axis == .horizontal {
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        content
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Enums

enum ViewAlignmentAxis {
    case vertical
    case horizontal
    case both
}

// MARK: - Extension

extension View {
    func centered(_ axis: ViewAlignmentAxis) -> some View {
        return self.modifier(CenteredViewModifier(axis: axis))
    }
}

// MARK: - Preview

struct CenteredViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Some text")
            .centered(.horizontal)
    }
}
