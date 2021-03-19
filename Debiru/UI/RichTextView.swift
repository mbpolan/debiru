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
    
    init(_ html: String) {
        self.html = html
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let view = NSTextField()
        view.isEditable = false
        view.isBezeled = false
        view.isSelectable = true
        view.drawsBackground = false
        view.textColor = NSColor.textColor
        
        DispatchQueue.main.async {
            let data = Data(self.html.utf8)
            
            if let rendered = try? NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil) {
                
                let range = NSMakeRange(0, rendered.length)
                let font = NSFont.preferredFont(forTextStyle: .body, options: [:])
                rendered.addAttribute(.font, value: font, range: range)
                rendered.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
                view.attributedStringValue = rendered
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
    }
}
