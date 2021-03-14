//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

// MARK: - View

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    
    @ObservedObject private var viewModel: SidebarViewModel = SidebarViewModel()
    
    var body: some View {
        VStack {
            Picker(selection: $viewModel.selected, label: Text("")) {
                ForEach(appState.boards, id: \.self) { board in
                    Text(board.title)
                        .frame(maxWidth: .infinity)
                        .tag(board.id)
                }
            }
            
            if viewModel.watchedThreads.isEmpty {
                Spacer()
                Text("No watched threads")
                Spacer()
            } else {
                List(viewModel.watchedThreads, id: \.self) { thread in
                    Text("\(thread)")
                }
            }
        }
        .padding()
    }
}

class SidebarViewModel: ObservableObject {
    @EnvironmentObject var appState: AppState
    @Published var selected: String?
    @Published var boards: [Board]
    @Published var watchedThreads: [Int]
    
    struct Board: Identifiable, Hashable {
        let id: String
        let label: String
    }
    
    init() {
        self.boards = []
        self.watchedThreads = []
    }
}

// MARK: - Preview

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}
