//
//  ContentView.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Combine
import SwiftUI

// MARK: - View

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: ContentViewModel = ContentViewModel()
    
    private let dataProvider: DataProvider
    private let showBoardPublisher = NotificationCenter.default.publisher(for: .showBoard)
    private let showThreadPublisher = NotificationCenter.default.publisher(for: .showThread)
    private let showImagePublisher = NotificationCenter.default.publisher(for: .showImage)
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        NavigationView {
            SidebarView()
            
            switch appState.currentItem {
            case .board(_):
                CatalogView()
            
            case .thread(_, _):
                ThreadView()
                
            default:
                if viewModel.pendingBoards != nil {
                    ProgressView("Loading")
                } else {
                    EmptyView()
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            viewModel.pendingBoards = dataProvider.getBoards(handleBoards)
        }
        .onChange(of: appState.quickSearchOpen) { open in
            viewModel.openSheet = open ? .quickSearch : nil
        }
        .onReceive(showBoardPublisher) { event in
            if let board = event.object as? Board {
                handleShowBoard(board)
            }
        }
        .onReceive(showThreadPublisher) { event in
            if let thread = event.object as? Thread {
                handleShowThread(thread)
            }
        }
        .onReceive(showImagePublisher) { event in
            if let data = event.object as? Data {
                handleShowImage(data)
            }
        }
        .sheet(item: $viewModel.openSheet, onDismiss: handleSheetDismiss) { sheet in
            makeSheet(sheet)
        }
    }
    
    private func makeSheet(_ sheet: ContentViewModel.Sheet) -> some View {
        switch sheet {
        case .error:
            return makeErrorSheet()
                .toErasedView()
        case .quickSearch:
            return QuickSearchView(shown: $appState.quickSearchOpen)
                .toErasedView()
        }
    }
    
    private func makeErrorSheet() -> some View {
        VStack {
            Text(viewModel.error?.message ?? "Unknown")
            HStack {
                Spacer()
                Button("OK") {
                    viewModel.openSheet = nil
                    viewModel.error = nil
                }
            }
        }
        .padding()
    }
    
    private func handleSheetDismiss() {
        switch viewModel.openSheet {
        case .error:
            viewModel.error = nil
        default:
            break
        }
        
        viewModel.openSheet = nil
    }
    
    private func handleShowBoard(_ board: Board) {
        appState.currentItem = .board(board)
        
        // add this board to our open items view, if it's not there already
        if !appState.openItems.contains(where: { $0 == .board(board) }) {
            appState.openItems.append(.board(board))
        }
    }
    
    private func handleShowThread(_ thread: Thread) {
        switch appState.currentItem {
        case .board(let board):
            appState.currentItem = .thread(board, thread)
        default:
            break
        }
    }
    
    private func handleShowImage(_ data: Data) {
        if let url = URL(string: "debiru://image") {
            appState.openImageData = data
            openURL(url)
        }
    }
    
    private func handleBoards(_ result: Result<[Board], Error>) {
        switch result {
        case .success(let boards):
            appState.boards = boards
        case .failure(let error):
            viewModel.error = ContentViewModel.ViewError(message: error.localizedDescription)
        }
        
        viewModel.pendingBoards = nil
    }
}

// MARK: - View Model

class ContentViewModel: ObservableObject {
    @Published var openSheet: Sheet?
    @Published var pendingBoards: AnyCancellable?
    @Published var error: ViewError?
    
    enum Sheet: Identifiable {
        case error
        case quickSearch
        
        var id: Int {
            hashValue
        }
    }
    
    struct ViewError: Identifiable {
        let message: String
        var id: UUID {
            UUID()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
