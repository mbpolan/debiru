//
//  RichTextView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftSoup
import SwiftUI

// MARK: - View

struct RichTextView: View {
    
    private let html: String
    
    init(_ html: String) {
        self.html = html
    }
    
    var body: some View {
        let views = renderHTML()
        
        VStack(spacing: 0) {
            ForEach(0..<views.count, id: \.self) { i in
                views[i]
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func renderHTML() -> [AnyView] {
        do {
            // remove <wbr> elements to avoid breaking links
            let sanitized = html.replacingOccurrences(of: "<wbr>", with: "")
            
            let doc: Document = try SwiftSoup.parseBodyFragment(sanitized)
            if let body = doc.body() {
                return try renderNode(body, attributes: .empty)
            } else {
                return []
            }
        } catch let error {
            print(error)
            return [Text(error.localizedDescription).toErasedView()]
        }
    }
    
    struct Attributes {
        let bold: Bool
        let italics: Bool
        let quote: Bool
        let quoteLink: Bool
        let spoiler: Bool
        let href: String?
        
        static var empty: Attributes {
            return Attributes(
                bold: false,
                italics: false,
                quote: false,
                quoteLink: false,
                spoiler: false,
                href: nil)
        }
    }
    
    private func renderNode(_ node: Node, attributes: Attributes) throws -> [AnyView] {
        var views: [AnyView] = []
        try node.getChildNodes().forEach { child in
            switch child {
            case let n as TextNode:
                views.append(renderTextNode(n, attributes: attributes))
            case let e as Element:
                views.append(contentsOf: try renderElement(e, attributes: attributes))
            default:
                views.append(AnyView(Text("unknown")))
            }
        }
        
        return views
    }
    
    private func renderElement(_ element: Element, attributes: Attributes) throws -> [AnyView] {
        if element.tagName() == "br" {
            return []
        } else if element.tagName() == "a" {
            let href = try element.attr("href")
            
            return try renderNode(element, attributes: Attributes(
                                    bold: attributes.bold,
                                    italics: attributes.italics,
                                    quote: attributes.quote,
                                    quoteLink: attributes.quoteLink || element.hasClass("quoteLink"),
                                    spoiler: attributes.spoiler,
                                    href: href))
            
        } else if element.tagName() == "span" {
            return try renderNode(element, attributes: Attributes(
                                    bold: attributes.bold,
                                    italics: attributes.italics,
                                    quote: attributes.quote || element.hasClass("quote"),
                                    quoteLink: attributes.quoteLink || element.hasClass("quoteLink"),
                                    spoiler: attributes.spoiler,
                                    href: attributes.href))
            
        } else if element.tagName() == "s" {
            return try renderNode(element, attributes: Attributes(
                                    bold: attributes.bold,
                                    italics: attributes.italics,
                                    quote: attributes.quote || element.hasClass("quote"),
                                    quoteLink: attributes.quoteLink || element.hasClass("quoteLink"),
                                    spoiler: true,
                                    href: attributes.href))
            
        } else {
            return [Text(element.tagName()).toErasedView()]
        }
    }
    
    private func renderTextNode(_ node: TextNode, attributes: Attributes) -> AnyView {
        var text = Text(node.text())
        
        if attributes.bold {
            text = text.bold()
        }
        
        if attributes.italics {
            text = text.italic()
        }
        
        if attributes.quote {
            text = text.foregroundColor(.green)
        }
        
        if attributes.spoiler {
            let view = text
                .foregroundColor(.black)
                .background(Color.black)
                .onHover { hovering in
                    if hovering {
                        
                    } else {
                        
                    }
                }
                .toErasedView()
            
            return view
        }
        
        if attributes.quoteLink,
           let link = attributes.href {
            return text
                .foregroundColor(.blue)
                .onTapGesture {
                    print(link)
                }
                .toErasedView()
        } else {
            return text.toErasedView()
        }
    }
}

// MARK: - Preview

struct RichTextView_Previews: PreviewProvider {
    private static let plain = "Just some text"
    
    private static let multiline = """
Text line 1<br>
Text line 2<br>
"""
    
    private static let single = "<span>this is my super long paragraph i sure hope it gets wrapped correctly</span>"
    
    private static let nested = "This is something<br><span class=\"quote\">&gt;this is my super long paragraph i sure hope it gets wrapped correctly</span>"
    
    private static let links = """
<a href=\"#p218664916\" class=\"quotelink\">&gt;&gt;218664916</a><br>
That looks cool.<br>
But I'm not digging it.
"""
    
    private static let spoiler = """
This is not a spoiler. <s>But this is</s>. And not this.
"""
    
    private static let quotes = "<span class=\"quote\">&gt;218664916</span><br>That looks cool."
    private static let empty = ""
    private static let html = spoiler
    
    static var previews: some View {
        HStack(alignment: .firstTextBaseline) {
            RichTextView(html)
        }
        .frame(width: 300)
    }
}
