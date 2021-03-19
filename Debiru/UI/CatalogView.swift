//
//  CatalogView.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

import AppKit
import Combine
import SwiftUI

// MARK: - View

struct CatalogView: View {
    @ObservedObject private var viewModel: CatalogViewModel = CatalogViewModel()
    private let dataProvider: DataProvider
    private let board: Board
    
    init(board: Board, dataProvider: DataProvider = FourChanDataProvider()) {
        self.board = board
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        List(viewModel.threads, id: \.self) { thread in
            HStack {
                if let asset = thread.attachment {
                    WebImage(asset,
                             board: board,
                             bounds: CGSize(width: 128.0, height: 128.0))
                }
                
                VStack(alignment: .leading) {
                    Text(thread.subject ?? "")
                        .font(.title)
                    
                    RichTextView(thread.content ?? "")
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.pendingThreads = dataProvider.getCatalog(for: board) { result in
                switch result {
                case .success(let threads):
                    viewModel.threads = threads
                case .failure(let error):
                    print(error)
                }
                
                viewModel.pendingThreads = nil
            }
        }
    }
}

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

// MARK: - View Model

class CatalogViewModel: ObservableObject {
    @Published var threads: [Thread] = []
    @Published var pendingThreads: AnyCancellable?
}

// MARK: - Preview

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(
            board: Board(
                        id: "f",
                        title: "Foobar",
                        description: "whatever"))
    }
}
