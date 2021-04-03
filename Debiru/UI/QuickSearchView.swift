//
//  FloatingPanel.swift
//  Debiru
//
//  Created by Mike Polan on 4/1/21.
//

import Carbon.HIToolbox.Events
import Introspect
import SwiftUI

// MARK: - View

struct QuickSearchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var text: String = ""
    @State private var selected: Int = 0
    @State private var monitor: Any?
    @State private var matches: [ViewableItem] = []
    @Binding var shown: Bool
    private let maxResults: Int = 5
    
    var body: some View {
        return VStack {
            TextField("Search", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.largeTitle)
                .padding(.top, 10)
                .padding([.leading, .bottom, .trailing], 5)
                .introspectTextField { (view: NSTextField) in
                    view.becomeFirstResponder()
                    view.focusRingType = .none
                }
                .onExitCommand {
                    shown = false
                }
            
            Divider()
            
            ForEach(0..<matches.count, id: \.self) { i in
                makeResultText(matches[i], index: i)
            }
            
            if !text.isEmpty && matches.isEmpty {
                Text("No matches found")
            }
        }
        .onAppear {
            self.monitor = NSEvent.addLocalMonitorForEvents(
                matching: .keyDown,
                handler: handleKeyDown)
        }
        .onDisappear {
            if let monitor = self.monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        .onChange(of: text) { filter in
            // update matching results and update selected index if it's no longer
            // in range of the next set of data
            self.matches = filterResults(filter)
            self.selected = selected >= matches.count ? 0 : selected
        }
        .frame(minWidth: 400)
        .edgesIgnoringSafeArea(.top)
    }
    
    private func handleActivate() {
        // hide the view and post a notification to open the selected item
        switch matches[selected] {
        case .board(let board):
            self.shown = false
            NotificationCenter.default.post(name: .showBoard, object: board)
            
        case .thread(_, _):
            break
        }
    }
    
    private func handleKeyDown(event: NSEvent) -> NSEvent? {
        switch Int(event.keyCode) {
        case kVK_UpArrow:
            cycleSelectedResult(-1)
            return nil
            
        case kVK_DownArrow:
            cycleSelectedResult(1)
            return nil
            
        case kVK_Return:
            guard !matches.isEmpty else { return event }
            handleActivate()
            return nil
            
        default:
            return event
        }
    }
    
    private func cycleSelectedResult(_ delta: Int) {
        DispatchQueue.main.async {
            let next = (selected + delta) % matches.count
            self.selected = next < 0 ? matches.count - 1 : next
        }
    }
    
    private func makeResultText(_ match: ViewableItem, index: Int) -> some View {
        let text: Text
        switch match {
        case .board(let board):
            text = Text("/\(board.id)/ - \(board.title)")
        case .thread(_, let thread):
            text = Text("\(thread.id) - \(thread.subject ?? thread.content ?? "")")
        }
        
        return HStack {
            Spacer()
            text.font(.title)
            Spacer()
            
        }
        .background(selected == index
                        ? Color(NSColor.selectedTextBackgroundColor)
                        : Color.clear)
        .frame(maxWidth: .infinity)
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
        }
        
        return Array(matches.prefix(maxResults))
    }
}

// MARK: - Preview

struct QuickSearchPanel_Previews: PreviewProvider {
    @State static var shown: Bool = true
    
    static var previews: some View {
        QuickSearchView(shown: $shown)
    }
}
