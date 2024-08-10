//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 7/16/24.
//

import SwiftUI

// MARK: - View

/// A view that displays a list of selectable boards.
struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(WindowState.self) private var windowState
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        ScrollView {
            DisclosureGroup(isExpanded: $viewModel.debiruExpanded) {
                Button(action: handleShowSavedThreads, label: {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "bookmark")
                            
                            Text("Saved Threads")
                            
                            Spacer()
                        }
                    }
                    .contentShape(Rectangle())
                })
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 10)
                .padding(.top, 7)
            } label: {
                Text("Debiru")
            }
            .padding(.horizontal, 5)
            
            DisclosureGroup(isExpanded: $viewModel.boardsExpanded) {
                LazyVStack {
                    ForEach(boards) { board in
                        Button(action: { handleBoard(board) }, label: {
                            HStack(alignment: .firstTextBaseline) {
                                Text("/\(board.id)/")
                                    .bold()
                                
                                Spacer()
                                
                                Text(board.title)
                            }
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 10)
                        .padding(.top, 7)
                    }
                }
            } label: {
                Text("Boards")
            }
            .padding(.horizontal, 5)
        }
        .navigationTitle("Boards")
        #if os(iOS)
        .searchable(text: $viewModel.filter)
        #endif
    }
    
    private var boards: [Board] {
        if viewModel.filter == "" {
            return appState.boards
        }
        
        return appState.boards.filter { board in
            if viewModel.filter.starts(with: "/") {
                return board.id.contains(viewModel.filter.trimmingCharacters(in: ["/"]))
            } else {
                return board.title.localizedCaseInsensitiveContains(viewModel.filter)
            }
        }
    }
    
    private func handleShowSavedThreads() {
        
    }
                               
   private func handleBoard(_ board: Board) {
       windowState.navigate(boardId: board.id)
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var filter: String = ""
    var debiruExpanded: Bool = true
    var boardsExpanded: Bool = true
}

// MARK: - Previews

#Preview {
    SidebarView()
        .environment(AppState(
            boards: [Board(id: "a",
                           title: "Animals",
                           description: "Animals and stuff",
                           features: .none)
            ]))
        .environment(WindowState())
}
