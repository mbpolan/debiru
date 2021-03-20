//
//  SearchBar.swift
//  Debiru
//
//  Created by Mike Polan on 3/19/21.
//

import Introspect
import SwiftUI

// MARK: - View

struct SearchBarView: View {
    @Binding var expanded: Bool
    @Binding var search: String
    
    var body: some View {
        HStack {
            if expanded {
                TextField("Search...", text: $search)
                    .introspectTextField { (textField: NSTextField) in
                        textField.becomeFirstResponder()
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minWidth: 150)
            }
            
            Image(systemName: "magnifyingglass")
                .onTapGesture { handleToggle() }
        }
    }
    
    private func handleToggle() {
        withAnimation {
            expanded = !expanded
        }
    }
}

// MARK: - Preview

struct SearchBarView_Previews: PreviewProvider {
    @State private static var expanded: Bool = true
    @State private static var search: String = ""
    
    static var previews: some View {
        SearchBarView(
            expanded: $expanded,
            search: $search)
    }
}
