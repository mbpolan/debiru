# Debiru

A native macOS reader for your favorite neighborhood imageboard.

![](screenshot.png)

## About

This project is intended to build a simple yet functional viewer for browsing the typical imageboards out there on the interwebs. It's not intended to be a replacement for what your browser can already do, but instead the aim is to make the experience feel more native for the macOS platform.

As an aside, this is also an experiement to see how much SwiftUI has progressed since its inception. An app like this will most likely make use of a large surface area of SwiftUI's capabilities, and for me, it's a good benchmark to see what's missing and what's easier than using AppKit directly.

### How about iOS?

TL;DR maybe one day.

Originally this project wasn't intended to support any target other than macOS, but there's been some traction to at least _try_ and see if an iOS flavor would work.
There are some promising signs that getting this app to render nicely on a smaller screen is feasible thanks to SwiftUI, and there's a few TODOs in the codebase
where additional work is needed to get to that point. This is open for contributions if anyone is interested in helping out. However, do note that it is not a high
priority relative to supporting macOS as a first class citizen.

## Developing

You'll need macOS 11.x and Xcode 12.4. 

Additionally, you'll need a recent version of [Sourcery](https://github.com/krzysztofzablocki/Sourcery), and
it must be on your path.

Afterwards, once you have all of the necessary tools, open the Xcode project, and build and run the app. 
Most dependencies are configured using Swift Package Manager, which Xcode should handle for you automatically.

## Contributing

All contributions are welcome! Feel free to open a pull request if there is something you'd like to pitch in for the project. 
