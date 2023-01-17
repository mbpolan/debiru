//
//  RichTextView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftUI

// MARK: - View

struct RichTextView: View {
    @State private var height: CGFloat?
    private let html: String
    private let boardId: String
    private let threadId: Int
    private let onLink: (_: URL) -> Void
    
    init(_ html: String, boardId: String, threadId: Int, onLink: @escaping(_: URL) -> Void) {
        let normalized = RichTextView.updateLinks(html, boardId: boardId, threadId: threadId)
        
        self.html = normalized
        self.boardId = boardId
        self.threadId = threadId
        self.onLink = onLink
    }
    
    var body: some View {
        GeometryReader { geo in
            TextViewWrapper(
                html,
                width: geo.size.width,
                onLink: onLink,
                onUpdate: handleUpdate)
        }.frame(height: height)
    }
    
    private static func updateLinks(_ html: String, boardId: String, threadId: Int) -> String {
        // expand relative post links with their full path including board and thread ids
        return html.replacingOccurrences(
            of: "\"#p([0-9]+)\"",
            with: "/\(boardId)/thread/\(String(threadId))/$1",
            options: .regularExpression)
    }
    
    private func handleUpdate(_ height: CGFloat) {
        DispatchQueue.main.async {
            self.height = height
        }
    }
}

// MARK: - Styles

fileprivate struct TextStyles {
    private static let baseStyles = { () -> String in
        let font = NSFont.preferredFont(forTextStyle: .body)
        let black = TextStyles.color(.black)
        let text = TextStyles.color(.textColor)
        let blue = TextStyles.color(.systemBlue)
        let yellow = TextStyles.color(.systemYellow)
        let violet = TextStyles.color(.systemPurple)
        let green = TextStyles.color(.systemGreen)
        
        // define standard styles. many of these come directly from the data source, and others are
        // ones that we inject ourselves via ContentProvider
        // TODO: find a way to generalize this with what's produced by ContentProvider
        return """
        <style>
        * {
          color: \(text);
          font-family: -apple-system;
          font-size: \(font.pointSize)px;
        }
        
        /* greentext and memes */
        .quote {
          color: \(green);
        }
        
        /* spoilers */
        s {
          background-color: \(text);
          text-decoration: none;
        }
        
        /* code styles */
        .prettyprint {
          font-family: monospace;
        }
        .pln {
          font-family: monospace;
        }
        .kwd {
          font-family: monospace;
          color: \(blue);
        }
        .typ {
          font-family: monospace;
          color: \(violet);
        }
        .pun {
          font-family: monospace;
          color: \(yellow);
        }
        .str {
          font-family: monospace;
          color: \(green);
        }
        </style>
    """
    }()
    
    private let styles: String
    
    init() {
        self.styles = TextStyles.baseStyles
    }
    
    func applyTo(_ html: String) -> String {
        return "\(styles)\(html)"
    }
    
    private static func color(_ nsColor: NSColor) -> String {
        // convert an NSColor into a css hex string in the rgb colorspace
        if let color = CIColor(color: nsColor) {
            let r = Int(round(color.red * 0xFF))
            let g = Int(round(color.green * 0xFF))
            let b = Int(round(color.blue * 0xFF))
            
            return NSString(format: "#%02X%02X%02X", r, g, b) as String
        }
        
        // default to inheritied color
        return "inherit"
    }
}

fileprivate struct TextViewWrapper: NSViewRepresentable {
    private static let styles: TextStyles = TextStyles()
    private let onLink: (_: URL) -> Void
    private let onUpdate: (_: CGFloat) -> Void
    private let html: String
    private let width: CGFloat
    private var string: NSMutableAttributedString?
    
    init(_ html: String,
         width: CGFloat,
         onLink: @escaping(_: URL) -> Void,
         onUpdate: @escaping(_: CGFloat) -> Void) {
        
        self.html = TextViewWrapper.styles.applyTo(html)
        self.width = width
        self.onLink = onLink
        self.onUpdate = onUpdate
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLink: onLink)
    }
    
    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.drawsBackground = false
        view.isEditable = false
        view.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        view.autoresizesSubviews = true
        view.autoresizingMask = .init([.width, .height])
        view.delegate = context.coordinator
        
        guard let string = makeString() else {
            print("Cannot render content")
            return view
        }
        
        context.coordinator.string = string
        view.textStorage?.setAttributedString(string)
        
        // apply additional constructs to the text (links, etc.) at this point.
        // we need to make the view editable *before* calling checkTextInDocument,
        // otherwise it will have no effect.
        view.isEditable = true
        view.checkTextInDocument(nil)
        view.isEditable = false
        
        recalculateHeight(string)
        
        return view
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {
        if let string = context.coordinator.string {
            recalculateHeight(string)
        }
    }
    
    private func recalculateHeight(_ string: NSMutableAttributedString) {
        let rect = string.boundingRect(
            with: NSMakeSize(width, .infinity),
            options: [.usesLineFragmentOrigin, .usesFontLeading])
        
        onUpdate(ceil(rect.height))
    }
    
    private func makeString() -> NSMutableAttributedString? {
        guard let string = NSMutableAttributedString(
            html: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil) else {
            
            return nil
        }
        
        return string
    }
}

// MARK: - Coordinator

extension TextViewWrapper {
    final class Coordinator: NSObject, NSTextViewDelegate {
        var string: NSMutableAttributedString?
        let onLink: (_: URL) -> Void
        
        init(onLink: @escaping(_: URL) -> Void) {
            self.onLink = onLink
        }
        
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let nsURL = link as? NSURL,
               let url = nsURL.absoluteURL {
                onLink(url)
            }
            
            return true
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
    
    private static let code = """
Leading text<br>
<pre class="prettyprint prettyprinted"><span class="pln">$var </span><span class="pun">=</span><span class="pln">&nbsp;</span><span class="kwd">GetStuff</span>
</pre>
"""
    private static let empty = ""
    private static let html = code
    
    static var previews: some View {
        VStack(alignment: .leading){
            Text("Reference text")
                .foregroundColor(.white)
            
            RichTextView(
                html,
                boardId: "f",
                threadId: 123,
                onLink: { _ in })
        }
        .frame(width: 500, height: 400)
    }
}
