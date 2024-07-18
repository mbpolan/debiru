//
//  PostView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import FlagKit
import SwiftUI

// MARK: - View

// A view that displays a post's content, author and other contextual information.
struct PostView: View {
    let post: Post
    private let formatter: RelativeDateTimeFormatter = .init()
    @Environment(\.deviceType) private var deviceType
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(post.author.name ?? "Anonymous")
                    .bold()
                
                if let country = post.author.country {
                    CountryFlagView(country: country)
                }
                
                Text(formatter.localizedString(for: post.date, relativeTo: .now))
            }
            
            if let asset = post.attachment {
                AssetView(asset: asset)
            }
            
            Text(post.body ?? "")
        }
    }
}

/// A view that displays a media asset.
fileprivate struct AssetView: View {
    let asset: Asset
    private let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        switch asset.fileType {
        case .image:
            AsyncImage(url: dataProvider.getURL(for: asset, variant: .thumbnail)) { img in
                img.image?.resizable().scaledToFit()
            }
        case .webm, .animatedImage:
            EmptyView()
        }
    }
}

/// A view that displays a country flag badge.
fileprivate struct CountryFlagView: View {
    let country: User.Country
    
    var body: some View {
        switch country {
        case .code(let code, let name):
            makeFlag(code)
        case .fake(let code, let name):
            Text("X")
        case .unknown:
            Text("?")
        }
    }
    
    private func makeFlag(_ code: String) -> some View {
        if let flag = Flag(countryCode: code) {
            return Image(uiImage: flag.image(style: .roundedRect))
        } else {
            return Image(systemName: "x")
        }
    }
}


// MARK: - Previews

#Preview {
    PostView(post: Post(id: 123,
                        boardId: "a",
                        threadId: 123,
                        isRoot: true,
                        author: User(name: "Anonymous", tripCode: nil, isSecure: false, tag: nil, country: .code(code: "PL", name: "Poland")),
                        date: Date(timeIntervalSince1970: 1700000000),
                        replyToId: nil,
                        subject: "Some subject line",
                        content: "This is a post content\nMulti-line!",
                        body: AttributedString(stringLiteral: "This is a post content\nMulti-line!"),
                        sticky: false,
                        closed: false,
                        spoileredImage: false,
                        attachment: nil,
                        threadStatistics: nil,
                        archived: false,
                        archivedDate: nil,
                        replies: []))
    .environment(\.deviceType, .defaultValue)
}
