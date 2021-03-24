//
//  WebImage.swift
//  Debiru
//
//  Created by Mike Polan on 3/17/21.
//

import Combine
import SwiftUI

// MARK: - View

struct WebImage: View {
    @StateObject private var viewModel: WebImageViewModel = WebImageViewModel()
    private let asset: Asset
    private let board: Board
    private let dataProvider: DataProvider = FourChanDataProvider()
    private let bounds: CGSize?
    
    init(_ asset: Asset, board: Board, bounds: CGSize? = nil) {
        self.asset = asset
        self.board = board
        self.bounds = bounds
    }
    
    var body: some View {
        let frame = getBounds()
        
        Group {
            switch viewModel.state {
            case .done(let image):
                makeImage(image)
                
            case .error(let error):
                Image(systemName: "exclamationmark.circle")
                    .help(error)
                    .imageScale(.large)
                    .frame(width: frame.width, height: frame.height)
                
            default:
                Text("...")
                    .frame(width: frame.width, height: frame.height)
            }
        }
        .onAppear(perform: self.load)
    }
    
    func load() {
        if viewModel.state == .empty {
            self.viewModel.state = .loading
            self.viewModel.pending = dataProvider.getImage(for: asset, board: board, completion: handleCompletion)
        }
    }
    
    private func getBounds() -> CGSize {
        if let bounds = self.bounds {
            return bounds
        }
        
        return CGSize(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
    }
    
    private func makeImage(_ nsImage: NSImage) -> some View {
        let image = Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
        
        let result: AnyView
        if let bounds = self.bounds {
            result = AnyView(
                image
                    .clipShape(RoundedRectangle(cornerRadius: 5.0))
                .frame(width: bounds.width, height: bounds.height))
        } else {
            result = AnyView(
                image
                .frame(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight)))
        }
        
        return result
    }
    
    private func handleCompletion(_ result: Result<Data, Error>) {
        switch result {
        case .success(let data):
            if let image = NSImage(data: data) {
                self.viewModel.state = .done(image)
            } else {
                self.viewModel.state = .error("This image is not valid")
            }
            
        case .failure(let error):
            print(error)
            self.viewModel.state = .error(error.localizedDescription)
        }
    }
}

// MARK: - View Model

class WebImageViewModel: ObservableObject {
    @Published var pending: AnyCancellable?
    @Published var state: State = .empty
    
    enum State: Equatable {
        case empty
        case loading
        case error(String)
        case done(NSImage)
    }
}
