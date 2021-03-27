//
//  SidebarView.swift
//  Debiru
//
//  Created by Mike Polan on 3/13/21.
//

import SwiftUI

// MARK: - View

struct SidebarView: View {
    @ObservedObject private var viewModel: SidebarViewModel = SidebarViewModel()
    
    var body: some View {
        VStack {
            Divider()
            
            HStack {
                SubviewImageButton(
                    subview: .openItems,
                    toggled: viewModel.subview == .openItems,
                    action: handleShowOpenItems)

                SubviewImageButton(
                    subview: .allBoards,
                    toggled: viewModel.subview == .allBoards,
                    action: handleShowAllBoards)

                SubviewImageButton(
                    subview: .watchedThreads,
                    toggled: viewModel.subview == .watchedThreads,
                    action: handleShowWatchedThreads)
            }
            .padding(1)
            
            Divider()
            
            switch viewModel.subview {
            case .openItems:
                OpenItemsView()
            case .allBoards:
                BoardListView()
            case .watchedThreads:
                WatchedThreadsView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: handleToggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    
    private func handleToggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil)
    }
    
    private func handleShowOpenItems() {
        viewModel.subview = .openItems
    }
    
    private func handleShowAllBoards() {
        viewModel.subview = .allBoards
    }
    
    private func handleShowWatchedThreads() {
        viewModel.subview = .watchedThreads
    }
}

// MARK: - SubviewImageButton

struct SubviewImageButton: View {
    let subview: SidebarViewModel.Subview
    let toggled: Bool
    let action: () -> Void
    
    var body: some View {
        let systemNameBase = getImageName()
        
        Button(action: action) {
            Image(systemName: toggled ? "\(systemNameBase).fill" : systemNameBase)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(toggled ? .blue : .primary)
    }
    
    private func getImageName() -> String {
        switch subview {
        case .allBoards:
            return "rectangle.3.offgrid.bubble.left"
        case .openItems:
            return "folder"
        case .watchedThreads:
            return "star"
        }
    }
}

// MARK: - View Model

class SidebarViewModel: ObservableObject {
    @Published var subview: Subview = .allBoards
    
    enum Subview {
        case allBoards
        case openItems
        case watchedThreads
    }
}

// MARK: - Preview

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(AppState())
    }
}
