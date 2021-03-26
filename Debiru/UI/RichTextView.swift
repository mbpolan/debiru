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
    let html: String
    
    var body: some View {
//        let no = html.components(separatedBy: " ").first ?? "?"
//        if no == "561987" {
//            print("\(no) - \(height ?? -1)")
//        }
//
        return GeometryReader { geo in
            TextViewWrapper(html, width: geo.size.width, onUpdate: handleUpdate)
        }.frame(height: height)
    }
    
    private func handleUpdate(_ height: CGFloat) {
        DispatchQueue.main.async {
            self.height = height
        }
    }
}

fileprivate struct TextViewWrapper: NSViewRepresentable {
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
    
    private let onUpdate: (_: CGFloat) -> Void
    private let html: String
    private let width: CGFloat
    private var string: NSMutableAttributedString?
    
    init(_ html: String, width: CGFloat, onUpdate: @escaping(_: CGFloat) -> Void) {
        self.html = "\(styles)\(html)"
        self.width = width
        self.onUpdate = onUpdate
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
        
        makeString { result in
            switch result {
            case .success(let string):
                context.coordinator.string = string
                view.textStorage?.setAttributedString(string)
                
                recalculateHeight(string)
            case .failure(let error):
                print("Cannot render content: \(error.localizedDescription)")
            }
        }
        
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
    
    private func makeString(_ handler: @escaping(_: Result<NSMutableAttributedString, Error>) -> Void) -> Void {
        DispatchQueue.main.async {
            guard let string = NSMutableAttributedString(
                    html: Data(html.utf8),
                    options: [.documentType: NSAttributedString.DocumentType.html],
                    documentAttributes: nil) else {
                
                handler(.failure(NSError()))
                return
            }
            
            let range = NSMakeRange(0, string.length)
            string.addAttribute(.font, value: NSFont.preferredFont(forTextStyle: .body, options: [:]), range: range)
            
            handler(.success(string))
        }
    }
}

// MARK: - Coordinator

extension TextViewWrapper {
    final class Coordinator: NSObject, NSTextViewDelegate {
        var string: NSMutableAttributedString?
        
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
