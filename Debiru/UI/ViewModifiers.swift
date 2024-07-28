//
//  ViewModifier.swift
//  Debiru
//
//  Created by Mike Polan on 7/25/24.
//

import SwiftUI

// MARK: - Post View List Item

/// A view modifier that decorates a PostView for displaying in a list.
struct PostViewListItem: ViewModifier {
    
    func body(content: Content) -> some View {
        content
        #if os(iOS)
            .listRowSeparator(.hidden)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 5)
                    .background(.clear)
                    .foregroundColor(Color(uiColor: UIColor.secondarySystemGroupedBackground))
                    .padding(
                        EdgeInsets(
                            top: 2,
                            leading: 10,
                            bottom: 2,
                            trailing: 10
                        )
                    )
            )
        #endif
    }
}

// MARK: - Post List

/// A view modifier that decorates a List for displaying a list of posts.
struct PostList: ViewModifier {
    
    func body(content: Content) -> some View {
        content
        #if os(iOS)
            .listStyle(.plain)
            .listRowSpacing(10)
        #endif
    }
}

// MARK: - Extensions

extension View {
    func postViewListItem() -> some View {
        modifier(PostViewListItem())
    }
    
    func postList() -> some View {
        modifier(PostList())
    }
}
