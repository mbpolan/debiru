//
//  ContentView.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import Combine
import SwiftUI

struct ContentView: View {
    private var appState: AppState = AppState()
    private var dataProvider: DataProvider = FourChanDataProvider()
    
    @ObservedObject private var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView()
            
            if viewModel.pendingBoards != nil {
                ProgressView("Loading")
            }
        }
        .environmentObject(appState)
        .onAppear {
            viewModel.pendingBoards = dataProvider.getBoards(handleBoards)
        }
        .sheet(item: $viewModel.error, onDismiss: {
            viewModel.error = nil
        }) { error in
            VStack {
                Text(error.message)
                HStack {
                    Spacer()
                    Button("OK") {
                        viewModel.error = nil
                    }
                }
            }
            .padding()
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

class ContentViewModel: ObservableObject {
    @Published var pendingBoards: AnyCancellable?
    @Published var error: ViewError?
    
    struct ViewError: Identifiable {
        let message: String
        var id: UUID {
            UUID()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
