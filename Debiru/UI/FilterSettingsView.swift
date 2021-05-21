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
                    items: viewModel.configuredBoardIds,
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
                if let selectedBoardFilters = viewModel.selectedBoardFilters {
                    Text("Hide posts and threads that contain any of the below terms.")
                        .padding()
                    
                    EditableList(
                        selection: $viewModel.selectedBoardFilter,
                        items: selectedBoardFilters,
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
        .onChange(of: viewModel.selectedBoardId) { boardId in
            if let boardId = boardId {
                viewModel.selectedBoardFilters = []
            } else {
                viewModel.selectedBoardFilters = nil
            }
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
                            viewModel.configuredBoardIds.append(addedBoard.id)
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
        return appState.boards.filter { !viewModel.configuredBoardIds.contains($0.id) }
    }
    
    private func handleAddBoard() {
        viewModel.addBoardSheetOpen = true
    }
    
    private func handleRemoveBoard(_ boardId: String) {
        if let index = viewModel.configuredBoardIds.firstIndex(of: boardId) {
            viewModel.selectedBoardId = nil
            viewModel.configuredBoardIds.remove(at: index)
        }
    }
    
    private func handleAddBoardFilter() {
        viewModel.selectedBoardFilters?.append(
            OrderedFilter(
                index: viewModel.selectedBoardFilters?.count ?? 0,
                filter: "..."))
    }
    
    private func handleRemoveBoardFilter(_ filter: OrderedFilter) {
        if let index = viewModel.selectedBoardFilters?.firstIndex(of: filter) {
            viewModel.selectedBoardFilters?.remove(at: index)
        }
    }
    
    private func handleApplyEditToFilter(at index: Int) {
        // find the targeted item
        if let filters = viewModel.selectedBoardFilters {
            viewModel.selectedBoardFilters = filters.enumerated().map { filter in
                return filter.offset == index
                    ? OrderedFilter(index: index, filter: viewModel.editedFilter)
                    : filter.element
            }
        }
        
        viewModel.editedFilter = ""
    }
    
    private func serializeToData() {
        
    }
}

class FilterSettingsViewModel: ObservableObject {
    @Published var configuredBoardIds: [String] = []
    @Published var selectedBoardId: String?
    @Published var selectedBoardFilters: [OrderedFilter]?
    @Published var selectedBoardFilter: OrderedFilter?
    @Published var addBoardSheetOpen: Bool = false
    @Published var addBoardSelected: Board?
    @Published var editedFilter: String = ""
}

struct OrderedFilter: Identifiable, Hashable, Equatable {
    let index: Int
    let filter: String
    
    var id: String {
        return "\(index)\(filter)"
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
