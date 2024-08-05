//
//  SearchView.swift
//  Debiru
//
//  Created by Mike Polan on 8/4/24.
//

import AppKit
import SwiftUI

// MARK: - View

/// A view that shows an interface for searching boards and other artifacts.
struct SearchView: View {
    @Environment(AppState.self) private var appState
    @Environment(WindowState.self) private var windowState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "magnifyingglass")
                    .padding(.horizontal, 10)
                    .font(.system(size: 20))
                    .foregroundStyle(.placeholder)
                
                TextField("", text: $viewModel.search)
                    .controlSize(.large)
                    .font(.system(size: 24))
                    .textFieldStyle(PlainTextFieldStyle())
                    .focusEffectDisabled()
                    .padding(.top, 5)
                    .padding(.trailing, 10)
            }
            
            if viewModel.results.count > 0 {
                Divider()
            }
            
            ForEach(Array(viewModel.results.enumerated()), id: \.element) { index, result in
                switch result {
                case .board(let boardID, let title):
                    HStack {
                        Text("/\(boardID)/")
                            .padding(.trailing, 10)
                            .font(.system(size: 20))
                            .lineLimit(1)
                        
                        Text(title)
                            .font(.system(size: 20))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(index == viewModel.selected ? Color.accentColor : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .onKeyPress(action: handleKeyPress)
        .onChange(of: viewModel.search, handleSearch)
        .frame(width: 500)
        .padding(5)
    }
    
    /// Handles a key press event.
    ///
    /// - Parameter e: The key press event.
    ///
    /// - Returns: The result of the event handler.
    private func handleKeyPress(_ e: KeyPress) -> KeyPress.Result {
        switch e.key {
        case .downArrow:
            viewModel.selected += 1
            if viewModel.selected >= viewModel.results.count {
                viewModel.selected = 0
            }
            
            return .handled
            
        case .upArrow:
            viewModel.selected -= 1
            if viewModel.selected < 0 {
                viewModel.selected = max(viewModel.results.count - 1, 0)
            }
            
            return .handled
            
        case .return:
            switch viewModel.results[viewModel.selected] {
            case .board(let boardID, _):
                windowState.navigate(boardId: boardID)
            }
            
            dismiss()
            return .handled
            
        default:
            return .ignored
        }
    }
    
    /// Handles a change to the search text.
    ///
    /// - Parameter oldValue: The previous search value.
    /// - Parameter newValue: The current search value.
    private func handleSearch(_ oldValue: String, _ newValue: String) {
        if newValue.isEmpty {
            viewModel.results = []
        } else if newValue.hasPrefix("/") {
            let term = newValue.trimmingCharacters(in: ["/"]).lowercased()
            viewModel.results = Array(appState.boards
                .filter { $0.id == term }
                .map { SearchResult.board($0.id, title: $0.title) }
                .prefix(5))
        } else {
            viewModel.results = Array(appState.boards
                .filter { $0.title.localizedCaseInsensitiveContains(newValue) }
                .map { SearchResult.board($0.id, title: $0.title) }
                .prefix(5))
        }
        
        if viewModel.selected >= viewModel.results.count {
            viewModel.selected = max(viewModel.results.count - 1, 0)
        }
    }
}

// MARK: - View Model

@Observable
fileprivate class ViewModel {
    var search: String = ""
    var selected: Int = 0
    var results: [SearchResult] = []
}

fileprivate enum SearchResult: Identifiable, Hashable {
    case board(_ boardID: String, title: String)
    
    var id: String {
        switch self {
        case .board(let boardID, _):
            return boardID
        }
    }
}

#Preview {
    SearchView()
        .environment(AppState())
}
