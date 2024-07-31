//
//  ViewModifier.swift
//  Debiru
//
//  Created by Mike Polan on 7/25/24.
//

import SwiftUI

// MARK: - Badge

/// A view modifier that shows a badge with a number.
///
/// If zero or a negative number is provided, the badge will not be shown. Quantities larger than 99 will
/// be truncated down to a string "99+" instead.
struct Badge: ViewModifier {
    let count: Int
    
    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Color.clear
                    
                    Text(self.text)
                        .font(.system(size: 16))
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                        .alignmentGuide(.top) { $0[.bottom] }
                        .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
                }
                .opacity(count == 0 ? 0 : 1)
            }
    }
    
    var text: String {
        return count > 99 ? "99+" : "\(count)"
    }
}

// MARK: - Post View List Item

/// A view modifier that decorates a PostView for displaying in a list.
struct PostViewListItem: ViewModifier {
    let post: Post
    
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
    func numberBadge(_ count: Int) -> some View {
        modifier(Badge(count: count))
    }
    
    func postViewListItem(_ post: Post) -> some View {
        modifier(PostViewListItem(post: post))
    }
    
    func postList() -> some View {
        modifier(PostList())
    }
}
