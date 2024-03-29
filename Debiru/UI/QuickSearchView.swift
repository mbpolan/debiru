//
//  QuickSearchView.swift
//  Debiru
//
//  Created by Mike Polan on 4/1/21.
//

import Introspect
import SwiftUI

#if os(macOS)
import Carbon.HIToolbox.Events
#endif

// MARK: - View

struct QuickSearchView: View {
    @AppStorage(StorageKeys.maxQuickSearchResults) var maxResults: Int =
        UserDefaults.standard.maxQuickSearchResults()
    
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: QuickSearchViewModel = QuickSearchViewModel()
    @Binding var shown: Bool
    
    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.title)
                .padding(.top, 10)
                .padding([.leading, .bottom, .trailing], 5)
                .introspectTextField { (view: PFTextField) in
                    view.becomeFirstResponder()
#if os(macOS)
                    view.focusRingType = .none
#endif
                }
#if os(macOS)
                .onExitCommand {
                    shown = false
                }
#endif
            Divider()
            
            // show a view for each matched item, with some padding added after the last result
            ForEach(0..<viewModel.matches.count, id: \.self) { i in
                makeResultText(viewModel.matches[i], index: i)
                    .padding(.bottom, i == viewModel.matches.count - 1 ? 5 : 0)
            }
            
            if !viewModel.text.isEmpty && viewModel.matches.isEmpty {
                Text("No matches found")
                    .padding(.bottom, 5)
            }
        }
        .onAppear {
#if os(macOS)
            viewModel.monitor = NSEvent.addLocalMonitorForEvents(
                matching: .keyDown,
                handler: handleKeyDown)
#endif
        }
        .onDisappear {
#if os(macOS)
            if let monitor = viewModel.monitor {
                NSEvent.removeMonitor(monitor)
                
                // avoid retain cycles when this view disappears
                viewModel.monitor = nil
            }
#endif
        }
        .onChange(of: viewModel.text) { filter in
            // update matching results and update selected index if it's no longer
            // in range of the next set of data
            viewModel.matches = filterResults(filter)
            viewModel.selected = viewModel.selected >= viewModel.matches.count
                ? 0
                : viewModel.selected
        }
        .frame(minWidth: 400)
        .padding([.leading, .trailing], 5)
        .edgesIgnoringSafeArea(.top)
    }
    
    private func makeResultText(_ match: ViewableItem, index: Int) -> some View {
        let text: Text
        switch match {
        case .board(let board):
            text = Text("/\(board.id)/ - \(board.title)")
        case .thread(_, let thread):
            text = Text("\(thread.id) - \(thread.subject ?? thread.content ?? "")")
        }
        
        // build a view containing the matching result, and set a background color if this is
        // the currently selected item in the list
        return HStack {
            Spacer()
            text.font(.title2)
                .padding([.top, .bottom], 1)
            Spacer()
            
        }
        .background(viewModel.selected == index
                        ? Color.accentColor
                        : Color.clear)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5.0, height: 5.0)))
        .frame(maxWidth: .infinity)
    }
    
    private func handleActivate() {
        // hide the view and post a notification to open the selected item
        switch viewModel.matches[viewModel.selected] {
        case .board(let board):
            self.shown = false
            BoardDestination(board: board, filter: nil)
                .notify()
            
        case .thread(_, _):
            break
        }
    }
#if os(macOS)
    private func handleKeyDown(event: NSEvent) -> NSEvent? {
        switch Int(event.keyCode) {
        case kVK_UpArrow:
            cycleSelectedResult(-1)
            return nil
            
        case kVK_DownArrow:
            cycleSelectedResult(1)
            return nil
            
        case kVK_Return:
            guard !viewModel.matches.isEmpty else { return event }
            handleActivate()
            return nil
            
        default:
            return event
        }
    }
#endif
    private func cycleSelectedResult(_ delta: Int) {
        DispatchQueue.main.async {
            let next = (viewModel.selected + delta) % viewModel.matches.count
            viewModel.selected = next < 0 ? viewModel.matches.count - 1 : next
        }
    }
    
    private func filterResults(_ text: String) -> [ViewableItem] {
        var matches: [ViewableItem] = []
        
        // search by board ids
        // if the text is a single forward slash, match all boards
        // otherwise, match boards more specifically
        if text == "/" {
            matches = appState.boards
                .sorted(by: { $0.id < $1.id })
                .map { .board($0) }
            
        } else if text.starts(with: "/") {
            var boardId = String(text.dropFirst())
            
            // remove trailing slashes if there are any
            boardId = boardId.replacingOccurrences(of: "/", with: "")
            
            // prefer an exact match
            if let exact = appState.boards.first(where: { $0.id == boardId }) {
                matches = [.board(exact)]
            }
            
            // remaining matches
            matches = matches + appState.boards
                .filter { $0.id.contains(boardId) && $0.id != boardId }
                .map { .board($0) }
        } else {
            matches = appState.boards
                .filter { $0.title.localizedCaseInsensitiveContains(text) }
                .map { .board($0) }
        }
        
        return Array(matches.prefix(maxResults))
    }
}

// MARK: - View Model

class QuickSearchViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var selected: Int = 0
    @Published var matches: [ViewableItem] = []
    @Published var monitor: Any?
}

// MARK: - Preview

struct QuickSearchPanel_Previews: PreviewProvider {
    @State static var shown: Bool = true
    
    static var previews: some View {
        QuickSearchView(shown: $shown)
    }
}
