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
    @StateObject private var viewModel: ContentViewModel = ContentViewModel()
    
    private let dataProvider: DataProvider
    private let showImagePublisher = NotificationCenter.default.publisher(for: .showImage)
    private let showWebVideoPublisher = NotificationCenter.default.publisher(for: .showWebVideo)
    
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
                    PlaceholderView()
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            viewModel.pendingBoards = dataProvider.getBoards(handleBoards)
        }
        .onDisappear {
            viewModel.threadWatcher?.invalidate()
            viewModel.threadWatcher = nil
        }
        .onChange(of: appState.quickSearchOpen) { open in
            viewModel.openSheet = open ? .quickSearch : nil
        }
        .onChange(of: appState.watchedThreads) { watchedThreads in
            // update the application badge icon whenever a change is done on the
            // list of watched threads
            NotificationManager.shared?.updateApplicationBadge()
        }
        .onReceiveShowBoard { board in
            handleShowBoard(board)
        }
        .onReceiveShowThread { thread in
            handleShowThread(thread)
        }
        .onReceive(showImagePublisher) { event in
            if let data = event.object as? DownloadedAsset {
                handleShowImage(data)
            }
        }
        .onReceive(showWebVideoPublisher) { event in
            if let asset = event.object as? Asset {
                handleShowWebVideo(asset)
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
    
    private func handleShowBoard(_ destination: BoardDestination) {
        appState.currentItem = .board(destination.board)
    }
    
    private func handleShowThread(_ destination: ThreadDestination) {
        switch destination {
        case .thread(let thread):
            switch appState.currentItem {
            case .board(let board):
                appState.currentItem = .thread(board, thread)
            default:
                break
            }
            
        case .watchedThread(let watchedThread):
            appState.currentItem = .thread(nil, watchedThread.thread)
            appState.targettedPostId = watchedThread.lastPostId
        }
    }
    
    private func handleShowImage(_ data: DownloadedAsset) {
        if let url = URL(string: "debiru://image") {
            appState.openImageData = data
            openURL(url)
        }
    }
    
    private func handleShowWebVideo(_ asset: Asset) {
        if let url = URL(string: "debiru://webVideo") {
            appState.openWebVideo = asset
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
    @Published var threadWatcher: Timer?
    
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
