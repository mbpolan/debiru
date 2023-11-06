//
//  CaptchaV3View.swift
//  Debiru
//
//  Created by Mike Polan on 11/27/22.
//

import SwiftSoup
import SwiftUI
import WebKit

struct CaptchaV3View: View {
    @StateObject private var viewModel: CaptchaV3ViewModel = .init()
    @Binding var challenge: String
    @Binding var solution: String
    let boardId: String
    let threadId: Int
    var dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        VStack {
            HStack {
                Text("Solution")
                
                TextField("", text: $solution)
                
                Button(action: handleRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            
            switch viewModel.state {
            case .loading:
                CaptchaV3LoaderView(boardId: boardId,
                                    threadId: threadId,
                                    onReady: handleReady,
                                    dataProvider: dataProvider)
                
            case .loaded(let captcha):
                if let twister = captcha.twister {
                    CaptchaV3TwisterView(fgImage: twister.image,
                                         bgImage: twister.background,
                                         bgSize: twister.backgroundSize,
                                         fgSize: twister.imageSize)
                } else {
                    Text("Unsupport verification method :(")
                }
            }
        }
    }
    
    func handleRefresh() {
        viewModel.state = .loading
    }
    
    private func handleReady(_ captcha: CaptchaV3Challenge) {
        viewModel.state = .loaded(captcha)
        challenge = captcha.twister?.challenge ?? ""
    }
}

fileprivate class CaptchaV3ViewModel: ObservableObject {
    @Published var state: State = .loading
    
    enum State {
        case loading
        case loaded(_ captcha: CaptchaV3Challenge)
    }
}

#if os(macOS)
fileprivate struct CaptchaV3LoaderView: NSViewRepresentable {
    let boardId: String
    let threadId: Int
    let onReady: (_ captcha: CaptchaV3Challenge) -> Void
    var dataProvider: DataProvider = FourChanDataProvider()
    
    func makeCoordinator() -> Coordinator {
        CaptchaV3LoaderView.Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 75))
        view.setValue(false, forKey: "drawsBackground")
        view.navigationDelegate = context.coordinator
        
        // FIXME: this shouldn't be in the view
        view.load(URLRequest(url: URL(string: "https://sys.4chan.org/captcha?framed=1&board=\(boardId)&thread_id=\(threadId)")!))
        
        return view
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}

#elseif os(iOS)
fileprivate struct CaptchaV3LoaderView: UIViewRepresentable {
    let boardId: String
    let threadId: Int
    let onReady: (_ captcha: CaptchaV3Challenge) -> Void
    var dataProvider: DataProvider = FourChanDataProvider()
    
    func makeCoordinator() -> Coordinator {
        CaptchaV3LoaderView.Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 75))
        view.setValue(false, forKey: "drawsBackground")
        view.navigationDelegate = context.coordinator
        
        // FIXME: this shouldn't be in the view
        view.load(URLRequest(url: URL(string: "https://sys.4chan.org/captcha?framed=1&board=\(boardId)&thread_id=\(threadId)")!))
        
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

#endif

extension CaptchaV3LoaderView {
    fileprivate class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: CaptchaV3LoaderView
        
        init(_ parent: CaptchaV3LoaderView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
            decisionHandler(.allow, preferences)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print(error)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print(error)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // extract the html in the captcha response
            webView.evaluateJavaScript("document.documentElement.outerHTML", completionHandler: { result, error in
                guard let html = result as? String else {
                    return
                }
                
                do {
                    // extract the captcha message contained in the document
                    // ideally we should load the page in a web view and set up message handlers to "properly" receive
                    // the message instead. the javascript here seems to do something weird with iframes and whatnot,
                    // so this will need more investigation.
                    let message = try self.parent.dataProvider.getCaptchaV3(from: html)
                    self.parent.onReady(message)
                } catch {
                    print(error)
                }
            })
        }
    }
}

fileprivate struct CaptchaV3TwisterView: View {
    let fgImage: Data
    let bgImage: Data
    let bgSize: CGSize
    let fgSize: CGSize
    
    var body: some View {
        ScrollView(.horizontal) {
            image
                .frame(width: fgSize.width * 2, height: fgSize.height)
        }
        .background {
            background
        }
        .frame(width: bgSize.width, height: bgSize.height)
    }
    
    private var image: Image {
        if let img = PFMakeImage(data: fgImage) {
            return img
        }
        
        return PFMakeImage(PFImage())
    }
    
    private var background: Image {
        if let img = PFMakeImage(data: bgImage) {
            return img
        }
        
        return PFMakeImage(PFImage())
    }
}

//struct CaptchaV3View_Previews: PreviewProvider {
//    @State static var solution: String = ""
//    
//    static let bg = Data(base64Encoded: "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")
//    
//    static let img = Data(base64Encoded: "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")
//    
//    static var previews: some View {
//        CaptchaV3View(captcha: .init(twister: .init(
//            challenge: "foo",
//            image: img!,
//            background: bg!,
//            imageSize: CGSize(width: 256.0, height: 80.0),
//            backgroundSize: CGSize(width: 314, height: 80.0))))
//    }
//}
