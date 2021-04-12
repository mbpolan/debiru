//
//  AnimatedImage.swift
//  Debiru
//
//  Created by Mike Polan on 4/11/21.
//

import AVKit
import SwiftUI

// MARK: - View

struct AnimatedImageView: NSViewRepresentable {
    let data: Data
    let frame: NSSize
    
    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.layer = CALayer()
        view.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
        view.wantsLayer = true
        
        // create a key frame animation representing the image
        if let animation = makeAnimation() {
            view.layer?.add(animation, forKey: "contents")
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
    }
    
    private func makeAnimation() -> CAKeyframeAnimation? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Cannot generate animated image")
            return nil
        }
        
        let numFrames = CGImageSourceGetCount(source)
        var maxWidth: Int = 0
        var maxHeight: Int = 0
        var duration: Double = 0.0
        
        // process each key frame
        let keyFrames: [Frame] = (0..<numFrames).compactMap { index in
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                print("Cannot get frame \(index) data")
                return nil
            }
            
            var delay: Double = 0.0
            
            if let props: NSDictionary = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
               let gif = props[kCGImagePropertyGIFDictionary] as? NSDictionary {
                
                // determine the frame delay, giving precedence to the unclamped delay property
                // if it exists
                delay =
                    (gif[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue ??
                    (gif[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue ??
                    0.0
                
                // find the width of this frame, and compare it against the largest width
                // across all frames
                if let width = props[kCGImagePropertyPixelWidth] as? NSNumber,
                   width.intValue > maxWidth {
                    maxWidth = width.intValue
                }
                
                // same for the height of the frame
                if let height = props[kCGImagePropertyPixelWidth] as? NSNumber,
                   height.intValue > maxHeight {
                    maxHeight = height.intValue
                }
            }
            
            // track the total animation duration
            duration += delay
            
            return Frame(
                data: frame,
                delay: delay)
        }
        
        // compute when each key frame should be animated
        var timeMarkers: [Double] = [0.0]
        keyFrames.forEach { frame in
            if let last = timeMarkers.last {
                timeMarkers.append(last + (frame.delay / duration))
            }
        }
        
        // animation timing must end with 1.0
        timeMarkers.append(1.0)
        
        // prepare an animation representing this image
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = keyFrames.reduce(0) { time, frame in
            return time + frame.delay
        }
        animation.repeatCount = .greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.calculationMode = .discrete
        animation.values = keyFrames.map { $0.data }
        animation.keyTimes = timeMarkers.map { $0 as NSNumber }
        
        return animation
    }
}

// MARK: - Extensions

extension AnimatedImageView {
    struct Frame {
        let data: CGImage
        let delay: Double
    }
}

// MARK: - Previews

struct AnimatedImageView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            if let data = try! Data(contentsOf: URL(string: "file:///Users/mike/test.gif")!) {
                AnimatedImageView(data: data,
                                  frame: NSSize(width: 128, height: 128))
                    .frame(width: 128, height: 128)
            } else {
                Text("Cannot load data")
            }
            
            Text("Content")
        }
    }
}
