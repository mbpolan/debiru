//
//  ThreadListCellView.swift
//  Debiru
//
//  Created by Mike Polan on 3/26/21.
//

import SwiftUI

// MARK: - View

struct ThreadListCellView: View {
    private let thread: Thread
    
    init(_ thread: Thread) {
        self.thread = thread
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(thread.boardId)
                .font(.title)
            
            Text("\(thread.id)")
                .font(.headline)
        }
    }
}

// MARK: - Preview

struct ThreadListCellView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListCellView(Thread(
                            id: 123,
                            boardId: "/foo",
                            poster: "Anonymous",
                            date: Date(),
                            subject: nil,
                            content: nil,
                            sticky: false,
                            closed: false,
                            attachment: nil))
    }
}
