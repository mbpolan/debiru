//
//  FilterSettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 5/8/21.
//

import SwiftUI

// MARK: - View

struct FilterSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage(StorageKeys.boardWordFilters) private var boardWordFilters: Data = Data()
    @State private var configuredBoardIds: [String] = []
    @State private var selectedBoardId: String?
    @State private var selectedBoardFilters: [String]?
    @State private var selectedBoardFilter: String?
    @State private var addBoardSheetOpen: Bool = false
    @State private var addBoardSelected: Board?
    
    var body: some View {
        HSplitView {
            VStack {
                EditableList(
                    selection: $selectedBoardId,
                    items: configuredBoardIds,
                    onAdd: handleAddBoard,
                    onRemove: { handleRemoveBoard($0) }) { item in
                    Text("/\(item)/")
                }
            }
            .border(Color(NSColor.darkGray), width: 1)
            .layoutPriority(1)
            
            Spacer()
                .frame(width: 5)
            
            VStack {
                if let selectedBoardFilters = selectedBoardFilters {
                    Text("Hide posts and threads that contain any of the below terms.")
                    
                    EditableList(
                        selection: $selectedBoardFilter,
                        items: selectedBoardFilters,
                        onAdd: handleAddBoard,
                        onRemove: { handleRemoveBoardFilter($0) }) { item in
                        Text(item)
                    }
                } else {
                    Text("Select or add a board from the left")
                        .centered(.both)
                }
            }
            .border(Color(NSColor.darkGray), width: 1)
            .layoutPriority(3)
        }
        .onChange(of: selectedBoardId) { boardId in
            if let boardId = boardId {
                selectedBoardFilters = []
            } else {
                selectedBoardFilters = nil
            }
        }
        .sheet(isPresented: $addBoardSheetOpen) {
            VStack {
                Picker("Select a board", selection: $addBoardSelected) {
                    ForEach(selectableBoards, id: \.id) { board in
                        Text("/\(board.id)/ - \(board.title)")
                            .tag(board as Board?)
                    }
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        addBoardSheetOpen = false
                    }
                    
                    Button("OK") {
                        addBoardSheetOpen = false
                        
                        if let addedBoard = addBoardSelected {
                            configuredBoardIds.append(addedBoard.id)
                            addBoardSelected = nil
                        }
                    }
                    .disabled(addBoardSelected == nil)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(minWidth: 200)
            .padding()
        }
        .frame(width: 400, height: 300)
    }
    
    private var selectableBoards: [Board] {
        return appState.boards.filter { !configuredBoardIds.contains($0.id) }
    }
    
    private func handleAddBoard() {
        addBoardSheetOpen = true
    }
    
    private func handleRemoveBoard(_ boardId: String) {
        if let index = configuredBoardIds.firstIndex(of: boardId) {
            selectedBoardId = nil
            configuredBoardIds.remove(at: index)
        }
    }
    
    private func handleAddBoardFilter() {
        
    }
    
    private func handleRemoveBoardFilter(_ filter: String) {
        
    }
    
    private func serializeToData() {
    }
}

fileprivate struct EditableList<T, Content>: View where T: Hashable, Content: View {
    @Binding var selection: T?
    let items: [T]
    let onAdd: () -> Void
    let onRemove: (_: T) -> Void
    let content: (_: T) -> Content
    
    var body: some View {
        VStack {
            List(items, id: \.self, selection: $selection) { item in
                content(item)
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline) {
                Button(action: {
                    onAdd()
                }, label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color(NSColor.systemGray))
                })
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if let selection = selection {
                        onRemove(selection)
                    }
                }, label: {
                    Image(systemName: "minus")
                        .foregroundColor(Color(NSColor.systemGray))
                })
                .buttonStyle(PlainButtonStyle())
                .disabled(selection == nil)
                
                Spacer()
            }
            .padding([.leading, .bottom], 5)
        }
    }
}

// MARK: - Preview

struct FilterSettingsView_Preview: PreviewProvider {
    static var appState = AppState()
    
    static var previews: some View {
        FilterSettingsView()
            .environmentObject(appState)
    }
}
