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
    
    init(dataProvider: DataProvider = FourChanDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
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
        .task(handleLoadBoards)
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
        .onShowBoard { handleShowBoard($0) }
        .onShowThread { handleShowThread($0) }
        .onShowImage { handleShowImage($0) }
        .onShowVideo { handleShowWebVideo($0) }
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
    
    @MainActor
    @Sendable private func handleLoadBoards() async {
        do {
            let boards = try await dataProvider.getBoards()
            appState.boards = boards
        } catch {
            print("Failed to load boards: \(error)")
            viewModel.error = ContentViewModel.ViewError(message: error.localizedDescription)
        }
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
    
    private func handleShowImage(_ asset: Asset) {
        if let url = URL(string: "debiru://image") {
            appState.openImageAsset = asset
            openURL(url)
        }
    }
    
    private func handleShowWebVideo(_ asset: Asset) {
        if let url = URL(string: "debiru://webVideo") {
            appState.openWebVideo = asset
            openURL(url)
        }
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
