//
//  RichTextView.swift
//  Debiru
//
//  Created by Mike Polan on 3/18/21.
//

import SwiftUI

// MARK: - View

struct RichTextView: NSViewRepresentable {
    private let html: String
    private let styles = """
<style>
* {
  color: white;
}
.quote {
  color: green;
}
.quotelink {
  color: blue;
  cursor: pointer;
}
</style>
"""
    
    init(html: String) {
        self.html = "\(styles)\(html)"
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.drawsBackground = false
        view.isEditable = false
        view.autoresizesSubviews = true
        view.autoresizingMask = .init([.width, .height])
        view.delegate = context.coordinator
        
        if let string = makeString() {
            view.textStorage?.setAttributedString(string)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) { }
    
    private func makeString() -> NSMutableAttributedString? {
        guard let string = NSMutableAttributedString(
                html: Data(html.utf8),
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil) else { return nil }
        
        let range = NSMakeRange(0, string.length)
        string.addAttribute(.font, value: NSFont.preferredFont(forTextStyle: .body, options: [:]), range: range)
        
        return string
    }
}

// MARK: - Coordinator

extension RichTextView {
    class Coordinator: NSObject, NSTextViewDelegate, NSTextDelegate {
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            
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
    private static let empty = ""
    private static let html = quotes
    
    static var previews: some View {
        HStack(alignment: .firstTextBaseline) {
            RichTextView(html: html)
        }
        .frame(width: 300)
    }
}
