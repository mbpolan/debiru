//
//  AlignedViewModifier.swift
//  Debiru
//
//  Created by Mike Polan on 5/30/21.
//

import SwiftUI

// MARK: - Vertical Alignment View Modifier

struct VerticallyAlignedViewModifier: ViewModifier {
    let alignment: GeneralAlignment
    
    func body(content: Content) -> some View {
        VStack {
            if alignment == .leading {
                content
                Spacer()
            } else {
                Spacer()
                content
            }
        }
    }
}

// MARK: - Horizontal Alignment View Modifier

struct HorizontallyAlignedViewModifier: ViewModifier {
    let alignment: GeneralAlignment
    
    func body(content: Content) -> some View {
        HStack {
            if alignment == .leading {
                content
                Spacer()
            } else {
                Spacer()
                content
            }
        }
    }
}

// MARK: - Models

enum GeneralAlignment {
    case leading
    case trailing
}

// MARK: - Extensions

extension View {
    func verticallyAligned(_ alignment: GeneralAlignment) -> some View {
        return self.modifier(VerticallyAlignedViewModifier(alignment: alignment))
    }
    
    func horizontallyAligned(_ alignment: GeneralAlignment) -> some View {
        return self.modifier(HorizontallyAlignedViewModifier(alignment: alignment))
    }
}

// MARK: - Preview

struct AlignedViewModifier_Preview: PreviewProvider {
    static var previews: some View {
        Form {
            Text("Whatever")
        }
        .verticallyAligned(.leading)
    }
}
