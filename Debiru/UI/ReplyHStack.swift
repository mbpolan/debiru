//
//  ReplyHStack.swift
//  Debiru
//
//  Created by Mike Polan on 4/29/21.
//

import SwiftUI

// MARK: - View

struct ReplyHStack: View {
    @StateObject private var viewModel: ReplyHStackModel = ReplyHStackModel()
    let postIds: [Int]
    let onTap: (_: Int) -> Void
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                makeItems(geo)
            }
        }
        .frame(height: viewModel.height)
    }
    
    private func makeItems(_ geo: GeometryProxy) -> some View {
        var origin = CGPoint(x: 0.0, y: 0.0)
        
        return ZStack(alignment: .topLeading) {
            ForEach(postIds, id: \.self) { postId in
                Text(">>\(String(postId))")
                    .foregroundColor(Color(PFLinkColor))
                    .fixedSize()
                    .lineLimit(nil)
                    .padding(.trailing, 5)
                    .onTapGesture { onTap(postId) }
                    .onHover { hover in
                        #if os(macOS)
                        if hover {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                        #endif
                    }
                    .alignmentGuide(.leading) { area in
                        if abs(area.width - origin.x) > geo.size.width {
                            origin.x = 0
                            origin.y -= area.height
                        }
                        
                        let x = origin.x
                        if postId == postIds.last {
                            origin.x = 0
                        } else {
                            origin.x -= area.width
                        }
                        
                        return x
                    }
                    .alignmentGuide(.top) { area in
                        let y = origin.y
                        if postId == postIds.last {
                            origin.y = 0
                        }
                        
                        return y
                    }
            }
        }
        .background(background($viewModel.height))
    }
    
    private func background(_ height: Binding<CGFloat>) -> some View {
        return GeometryReader { geo -> Color in
            let rect = geo.frame(in: .local)
            
            if rect.size.height != height.wrappedValue {
                DispatchQueue.main.async {
                    height.wrappedValue = rect.size.height
                }
            }
            
            return .clear
        }
    }
}

// MARK: - View Model

class ReplyHStackModel: ObservableObject {
    @Published var height: CGFloat = 0
}
