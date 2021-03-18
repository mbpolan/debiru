//
//  CatalogView.swift
//  Debiru
//
//  Created by Mike Polan on 3/15/21.
//

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
                    WebImage(asset, board: board)
                }
                
                Text(thread.subject ?? "")
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
