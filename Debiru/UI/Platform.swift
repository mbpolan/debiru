//
//  Platform.swift
//  Debiru
//
//  Created by Mike Polan on 11/5/23.
//

import Foundation

#if os(macOS)
import AppKit
import SwiftUI

typealias PFApplication = NSApplication
typealias PFColor = NSColor
typealias PFImage = NSImage
typealias PFTextField = NSTextField
typealias PFSize = NSSize
typealias PFViewRepresentable = NSViewRepresentable
typealias PFTextView = NSTextView
typealias PFFont = NSFont
typealias PFTextViewDelegate = NSTextViewDelegate

let PFPlaceholderTextColor = NSColor.placeholderTextColor
let PFTextColor = NSColor.textColor
let PFSecondaryLabelColor = NSColor.secondaryLabelColor
let PFLinkColor = NSColor.linkColor

func PFMakeImage(_ image: NSImage) -> Image {
    return Image(nsImage: image)
}

func PFMakeImage(systemName: String) -> Image {
    return Image(nsImage: NSImage(systemSymbolName: systemName, accessibilityDescription: nil) ?? NSImage())
}

func PFMakeImage(data: Data) -> Image? {
    guard let image = NSImage(data: data) else { return nil }
    return Image(nsImage: image)
}

#elseif os(iOS)
import UIKit
import SwiftUI

typealias PFApplication = UIApplication
typealias PFColor = UIColor
typealias PFImage = UIImage
typealias PFTextField = UITextField
typealias PFViewRepresentable = UIViewRepresentable
typealias PFTextView = UITextView
typealias PFFont = UIFont
typealias PFTextViewDelegate = UITextViewDelegate

struct PFSize {
    let width: CGFloat
    let height: CGFloat
    
    init(width: Int, height: Int) {
        self.width = CGFloat(width)
        self.height = CGFloat(height)
    }
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

let PFPlaceholderTextColor = UIColor.placeholderText
let PFTextColor = UIColor.black
let PFSecondaryLabelColor = UIColor.secondaryLabel
let PFLinkColor = UIColor.link

func PFMakeImage(_ image: UIImage) -> Image {
    return Image(uiImage: image)
}

func PFMakeImage(systemName: String) -> Image {
    return Image(uiImage: UIImage(systemName: systemName) ?? UIImage())
}

func PFMakeImage(data: Data) -> Image? {
    guard let image = UIImage(data: data) else { return nil }
    return Image(uiImage: image)
}

#endif
