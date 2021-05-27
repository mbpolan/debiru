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
    let initialContent: String?
    let onDismiss: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Name")
                TextField("Anonymous", text: $viewModel.name)
            }
            .padding(.bottom, 3)
            
            TextEditor(text: $viewModel.content)
            
            CaptchaView(onCaptchaResponse: handleCaptchaResponse)
                .frame(height: 100)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(Color(NSColor.systemRed))
            }
            
            HStack {
                Spacer()
                
                Button("Cancel", action: onDismiss)
                
                Button("Post", action: handlePost)
                    .disabled(!canPost)
            }
        }
        .padding()
        .frame(minWidth: 450, minHeight: 500)
        .onAppear {
            viewModel.content = initialContent ?? ""
        }
    }
    
    private var canPost: Bool {
        return viewModel.content.count > 0 &&
            viewModel.captchaToken != nil &&
            viewModel.postButtonEnabled
    }
    
    private func handleCaptchaResponse(_ event: CaptchaEvent) {
        switch event {
        case .success(let token):
            viewModel.captchaToken = token
        case .expired:
            viewModel.captchaToken = nil
        }
    }
    
    private func handlePost() {
        guard let captchaToken = viewModel.captchaToken,
              viewModel.content.count > 0 else { return }
        
        viewModel.error = nil
        viewModel.postButtonEnabled = false
        
        FourChanDataProvider().post(Submission(
                                        replyTo: replyTo,
                                        name: viewModel.name,
                                        content: viewModel.content,
                                        captchaToken: captchaToken),
                                    to: board) { result in
            
            DispatchQueue.main.async {
                viewModel.postButtonEnabled = true
                
                switch result {
                case .success():
                    onComplete()
                case .failure(let error):
                    viewModel.error = "Failed to submit post: \(error.localizedDescription)"
                    break
                }
            }
        }
    }
}

// MARK: - View Model

class PostEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var content: String = ""
    @Published var captchaToken: String?
    @Published var error: String?
    @Published var postButtonEnabled: Bool = true
}

// MARK: - Preview

struct PostEditorView_Preview: PreviewProvider {
    static var previews: some View {
        PostEditorView(
            board: Board(
                id: "f",
                title: "foo",
                description: "Foo bar"),
            replyTo: nil,
            initialContent: nil,
            onDismiss: { },
            onComplete: { })
            .frame(width: 400, height: 400)
    }
}

