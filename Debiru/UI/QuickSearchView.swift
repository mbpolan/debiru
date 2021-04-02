//
//  FloatingPanel.swift
//  Debiru
//
//  Created by Mike Polan on 4/1/21.
//

import Introspect
import SwiftUI

// MARK: - View

struct QuickSearchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var text: String = ""
    @Binding var shown: Bool
    
    var body: some View {
        VStack {
            TextField("Search", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.largeTitle)
                .padding(.top, 10)
                .padding([.leading, .bottom, .trailing], 5)
                .onExitCommand {
                    shown = false
                }
                .introspectTextField { view in
                    view.becomeFirstResponder()
                }
            
            Divider()
        }
        .frame(minWidth: 400)
        .cornerRadius(5.0)
        .edgesIgnoringSafeArea(.top)
    }
}

// MARK: - Preview

struct QuickSearchPanel_Previews: PreviewProvider {
    @State static var shown: Bool = true
    
    static var previews: some View {
        QuickSearchView(shown: $shown)
    }
}
