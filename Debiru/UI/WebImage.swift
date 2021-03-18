//
//  WebImage.swift
//  Debiru
//
//  Created by Mike Polan on 3/17/21.
//

import Combine
import SwiftUI

struct WebImage: View {
    @ObservedObject private var viewModel: WebImageViewModel = WebImageViewModel()
    private let asset: Asset
    private let board: Board
    private let dataProvider: DataProvider = FourChanDataProvider()
    private let bounds: CGSize?
    
    init(_ asset: Asset, board: Board) {
        self.asset = asset
        self.board = board
        self.bounds = nil
    }
    
    var body: some View {
        return Group {
            if viewModel.state == .done,
               let image = viewModel.data {
                makeImage(image)
            } else if viewModel.state == .error {
                Text(":(")
                    .frame(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
            } else {
                Text("...")
                    .frame(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
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
    
    private func makeImage(_ nsImage: NSImage) -> some View {
        let image = Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
        
        let result: AnyView
        if let bounds = self.bounds {
            result = AnyView(
                image
                .clipShape(Capsule())
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
                self.viewModel.data = image
                self.viewModel.state = .done
            } else {
                self.viewModel.state = .error
            }
            
        case .failure(let error):
            print(error)
            self.viewModel.state = .error
        }
    }
}

class WebImageViewModel: ObservableObject {
    @Published var pending: AnyCancellable?
    @Published var data: NSImage?
    @Published var state: State = .empty
    
    enum State {
        case empty
        case loading
        case error
        case done
    }
}
