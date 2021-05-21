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
    @ObservedObject private var viewModel: FilterSettingsViewModel = FilterSettingsViewModel()
    
    var body: some View {
        HSplitView {
            VStack {
                EditableList(
                    selection: $viewModel.selectedBoardId,
                    items: [String] (appState.boardFilters.keys),
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
                if let selectedBoardId = viewModel.selectedBoardId {
                    Text("Hide posts and threads that contain any of the below terms.")
                        .padding()
                    
                    EditableList(
                        selection: $viewModel.selectedBoardFilter,
                        items: appState.boardFilters[selectedBoardId] ?? [],
                        onAdd: handleAddBoardFilter,
                        onRemove: { handleRemoveBoardFilter($0) }) { item in
                        
                        Group {
                            if viewModel.selectedBoardFilter == item {
                                TextField(
                                    "",
                                    text: $viewModel.editedFilter,
                                    onEditingChanged: { _ in },
                                    onCommit: {
                                        handleApplyEditToFilter(at: item.index)
                                    })
                            } else {
                                Text(item.filter)
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedBoardFilter) { value in
                        viewModel.editedFilter = value?.filter ?? "..."
                    }
                } else {
                    Text("Select or add a board from the left")
                        .centered(.both)
                }
            }
            .border(Color(NSColor.darkGray), width: 1)
            .layoutPriority(3)
        }
        .onChange(of: appState.boardFilters) { _ in
            serializeToData()
        }
        .sheet(isPresented: $viewModel.addBoardSheetOpen) {
            VStack {
                Picker("Select a board", selection: $viewModel.addBoardSelected) {
                    ForEach(selectableBoards, id: \.id) { board in
                        Text("/\(board.id)/ - \(board.title)")
                            .tag(board as Board?)
                    }
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        viewModel.addBoardSheetOpen = false
                    }
                    
                    Button("OK") {
                        viewModel.addBoardSheetOpen = false
                        
                        if let addedBoard = viewModel.addBoardSelected {
                            appState.boardFilters[addedBoard.id] = []
                            viewModel.addBoardSelected = nil
                        }
                    }
                    .disabled(viewModel.addBoardSelected == nil)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(minWidth: 200)
            .padding()
        }
        .frame(width: 400, height: 300)
    }
    
    private var selectableBoards: [Board] {
        // allow selecting boards that aren't already in our filter list
        return appState.boards.filter { appState.boardFilters[$0.id] == nil }
    }
    
    private func handleAddBoard() {
        viewModel.addBoardSheetOpen = true
    }
    
    private func handleRemoveBoard(_ boardId: String) {
        viewModel.selectedBoardId = nil
        appState.boardFilters.removeValue(forKey: boardId)
    }
    
    private func handleAddBoardFilter() {
        guard let selectedBoardId = viewModel.selectedBoardId else { return }
        
        let existingFilters = appState.boardFilters[selectedBoardId] ?? []
        
        appState.boardFilters[selectedBoardId] = existingFilters + [
            OrderedFilter(
                index: existingFilters.count,
                filter: "...")
        ]
    }
    
    private func handleRemoveBoardFilter(_ filter: OrderedFilter) {
        guard let selectedBoardId = viewModel.selectedBoardId,
              let existingFilters = appState.boardFilters[selectedBoardId] else { return }
        
        appState.boardFilters[selectedBoardId] = existingFilters.filter {
            return $0 != filter
        }
    }
    
    private func handleApplyEditToFilter(at index: Int) {
        guard let selectedBoardId = viewModel.selectedBoardId,
              let existingFilters = appState.boardFilters[selectedBoardId] else { return }
        
        appState.boardFilters[selectedBoardId] = existingFilters.map {
            return $0.index == index
                ? OrderedFilter(index: index, filter: viewModel.editedFilter)
                : $0
        }
        
        viewModel.editedFilter = ""
    }
    
    private func serializeToData() {
        do {
            boardWordFilters = try JSONEncoder().encode(appState.boardFilters)
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
}

class FilterSettingsViewModel: ObservableObject {
    @Published var selectedBoardId: String?
    @Published var selectedBoardFilter: OrderedFilter?
    @Published var addBoardSheetOpen: Bool = false
    @Published var addBoardSelected: Board?
    @Published var editedFilter: String = ""
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
                .contentShape(Rectangle())
                
                Button(action: {
                    if let selection = selection {
                        onRemove(selection)
                    }
                }, label: {
                    Image(systemName: "minus")
                        .foregroundColor(Color(NSColor.systemGray))
                })
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
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
