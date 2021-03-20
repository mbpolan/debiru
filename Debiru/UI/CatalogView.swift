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
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: CatalogViewModel = CatalogViewModel()
    private let dataProvider: DataProvider
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        print(viewModel.threads.count)
        return List(viewModel.threads, id: \.self) { thread in
            HStack {
                if let board = getBoard(appState.currentItem),
                   let asset = thread.attachment {
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
        .navigationTitle(getNavigationTitle())
        .onChange(of: appState.currentItem) { item in
            reload(from: item)
        }
        .onAppear {
            reloadFromState()
        }
    }
    
    private func getNavigationTitle() -> String {
        if let board = getBoard(appState.currentItem) {
            return "/\(board.id)/"
        }
        
        return ""
    }
    
    private func getBoard(_ item: ViewableItem?) -> Board? {
        switch item {
        case .board(let board):
            return board
        default:
            return nil
        }
    }
    
    private func reloadFromState() {
        guard let board = getBoard(appState.currentItem) else { return }
        reload(board)
    }
    
    private func reload(from item: ViewableItem?) {
        guard let board = getBoard(item) else { return }
        reload(board)
    }
    
    private func reload(_ board: Board) {
        viewModel.pendingThreads = dataProvider.getCatalog(for: board) { result in
            switch result {
            case .success(let threads):
                self.viewModel.threads = threads
            case .failure(let error):
                print(error)
            }
            
            self.viewModel.pendingThreads = nil
            self.viewModel.objectWillChange.send()
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
    private static let board = Board(
        id: "f",
        title: "Foobar",
        description: "whatever")
    
    static var previews: some View {
        CatalogView()
            .environmentObject(AppState(
                                currentItem: .board(board),
                                boards: [board],
                                openItems: []))
    }
}
