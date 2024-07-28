//
//  PostView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import FlagKit
import SwiftUI

// MARK: - Data

enum AssetAction {
    case view
    case download
}

// MARK: - View

// A view that displays a post's content, author and other contextual information.
struct PostView: View {
    let post: Post
    var onTapGesture: (() -> Void)? = { }
    var onAssetAction: ((_: Asset, _: AssetAction) -> Void)? = { _, _ in }
    @Environment(\.deviceType) private var deviceType
    private static let formatter: RelativeDateTimeFormatter = .init()
    
    var body: some View {
        VStack(alignment: .leading) {
            // show the subject if one was given
            if let text = post.subject {
                subject(text)
                    .onTapGesture(perform: onTapGesture ?? { })
            }
            
            // show information about the author and post itself
            HStack(alignment: .center) {
                if post.sticky {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.green)
                        .help("This thread is pinned")
                }
                
                if post.closed {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.red)
                        .help("No replies can be posted in this thread")
                }
                
                if let country = post.author.country {
                    CountryFlagView(country: country)
                }
                
                Text(post.author.name ?? "Anonymous")
                    .bold()
                
                Text(PostView.formatter.localizedString(for: post.date, relativeTo: .now))
            }
            .onTapGesture(perform: onTapGesture ?? { })
            
            // render the asset and content
            body {
                if let asset = post.attachment {
                    ThumbnailView(asset: asset)
                        .padding(.trailing)
                        .onTapGesture(perform: { onAssetAction?(asset, .view) })
                        .onLongPressGesture(perform: { onAssetAction?(asset, .download) })
                }
                
                // align content text to the left
                HStack(alignment: .firstTextBaseline) {
                    Text(post.body ?? "")
                        .onTapGesture(perform: onTapGesture ?? { })
                        // enabling this breaks the url navigation :/
                        //.textSelection(.enabled)
                    
                    Spacer()
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func subject(_ text: String) -> some View {
        if deviceType == .iOS {
            Text(text)
                .font(.title3)
        } else {
            Text(text)
                .font(.title)
        }
    }
    
    private func body<Content : View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        Group {
            if deviceType == .iOS {
                VStack(content: content)
            } else {
                HStack(alignment: .top, content: content)
            }
        }
    }
}

/// A view that displays a media asset thumbnail.
fileprivate struct ThumbnailView: View {
    let asset: Asset
    private let dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        switch asset.fileType {
        case .image, .webm:
            AsyncImage(url: dataProvider.getURL(for: asset, variant: .thumbnail)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
            .frame(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5)))
            
        case .animatedImage:
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
                .clipShape(.circle)
                .help(name)
        case .fake(_, let name):
            Text("X")
                .clipShape(.circle)
                .help(name)
        case .unknown:
            Text("?")
        }
    }
    
    private func makeFlag(_ code: String) -> some View {
        if let flag = Flag(countryCode: code) {
            #if os(iOS)
            return Image(uiImage: flag.originalImage)
            #else
            return Image(nsImage: flag.originalImage)
            #endif
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
