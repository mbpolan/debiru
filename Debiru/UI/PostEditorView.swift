//
//  PostEditorView.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import SwiftUI

// MARK: - View

struct PostEditorView: View {
    @StateObject private var viewModel: PostEditorViewModel = PostEditorViewModel()
    let board: Board
    let replyTo: Int?
    
    var body: some View {
        VStack {
            HStack {
                Text("Name")
                TextField("Anonymous", text: $viewModel.name)
            }
            .padding(.bottom, 3)
            
            TextEditor(text: $viewModel.content)
            
            CaptchaView { viewModel.captchaToken = $0 }
                .frame(height: 80)
            
            HStack {
                Spacer()
                
                Button("Post", action: handlePost)
                    .disabled(!canPost)
            }
        }
        .padding()
    }
    
    private var canPost: Bool {
        return viewModel.content.count > 0 && viewModel.captchaToken != nil
    }
    
    private func handlePost() {
        guard let captchaToken = viewModel.captchaToken,
              viewModel.content.count > 0 else { return }
        
        FourChanDataProvider().post(Submission(
                                        replyTo: replyTo,
                                        name: viewModel.name,
                                        content: viewModel.content,
                                        captchaToken: captchaToken),
                                    to: board) { result in
            switch result {
            case .success(_):
                print("OK!")
                break
            case .failure(let error):
                print(error)
                break
            }
        }
    }
}

// MARK: - View Model

class PostEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var content: String = ""
    @Published var captchaToken: String?
}

// MARK: - Preview

struct PostEditorView_Preview: PreviewProvider {
    static var previews: some View {
        PostEditorView(
            board: Board(
                id: "f",
                title: "foo",
                description: "Foo bar"),
            replyTo: nil)
            .frame(width: 400, height: 400)
    }
}
