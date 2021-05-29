//
//  PostEditorView.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import SwiftUI
import UniformTypeIdentifiers

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
            LazyVGrid(columns: [
                GridItem(.fixed(50)),
                GridItem(.flexible()),
            ]) {
                Text("Name")
                TextField("Anonymous", text: $viewModel.name)
                
                Text("Image")
                HStack {
                    if let imageURL = viewModel.imageURL {
                        Text(imageURL.relativePath)
                    } else {
                        Text("Drag and drop or choose an image")
                            .foregroundColor(Color(NSColor.placeholderTextColor))
                    }
                    
                    Spacer()
                    Button("...", action: handleOpenImagePicker)
                }
                .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDropImage)
            }
            
            HStack {
                Toggle("Bump thread after posting", isOn: $viewModel.bump)
                Spacer()
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
    
    private func handleOpenImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Select image"
        
        panel.begin { result in
            if result == NSApplication.ModalResponse.OK {
                viewModel.imageURL = panel.url
            }
        }
    }
    
    private func handleDropImage(items: [NSItemProvider]) -> Bool {
        if let item = items.first,
           let identifier = item.registeredTypeIdentifiers.first,
           identifier == UTType.fileURL.identifier {
            
            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data {
                        viewModel.imageURL = NSURL(
                            absoluteURLWithDataRepresentation: urlData,
                            relativeTo: nil) as URL
                    } else if let error = error {
                        print(error)
                        viewModel.error = "Failed to load image"
                    }
                }
            }
            
            return true
        }
        
        return false
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
        
        let asset: AssetSubmission?
        if let imageURL = viewModel.imageURL,
           let imageData = try? Data(contentsOf: imageURL) {
            asset = AssetSubmission(
                data: imageData,
                fileName: imageURL.lastPathComponent)
        } else {
            asset = nil
        }
        
        FourChanDataProvider().post(Submission(
                                        replyTo: replyTo,
                                        name: viewModel.name,
                                        asset: asset,
                                        bump: viewModel.bump,
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
    @Published var imageURL: URL?
    @Published var bump: Bool = true
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

