//
//  WebImage.swift
//  Debiru
//
//  Created by Mike Polan on 3/17/21.
//

import Combine
import SwiftUI

// MARK: - View

struct WebImage: View {
    @StateObject private var viewModel: WebImageViewModel = WebImageViewModel()
    private let asset: Asset
    private let dataProvider: DataProvider = FourChanDataProvider()
    private let saveLocation: URL
    private let bounds: CGSize?
    private let onOpen: (_: Data?) -> Void
    
    init(_ asset: Asset,
         saveLocation: URL,
         bounds: CGSize? = nil,
         onOpen: @escaping(_: Data?) -> Void) {
        
        self.asset = asset
        self.saveLocation = saveLocation
        self.bounds = bounds
        self.onOpen = onOpen
    }
    
    var body: some View {
        let frame = getBounds()
        
        Group {
            switch viewModel.state {
            case .done(let image):
                makeImage(image)
                
            case .error(let error):
                makeErrorView(error, frame: frame)
                
            default:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: frame.width, height: frame.height)
            }
        }
        .popover(item: $viewModel.popoverType, arrowEdge: .leading) { item in
            HStack {
                if item == .success {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                }

                Text(viewModel.popoverMessage ?? "Something went wrong!")
            }
            .padding()
        }
        .onTapGesture(count: 2) {
            handleSaveImage()
        }
        .onTapGesture(count: 1) {
            onOpen(viewModel.imageData)
        }
        .onAppear(perform: self.load)
    }
    
    private func makeImage(_ data: Data) -> some View {
        let bounds = self.bounds ??
            CGSize(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
        
        // depending on the type of image this is, we need to either create a static
        // image view or an animated one instead. the set up is similar, but the underlying
        // views are radically different.
        let view: AnyView
        if asset.extension.caseInsensitiveCompare(".gif") == .orderedSame {
            view = AnimatedImageView(data: data,
                                     frame: NSSize(width: bounds.width, height: bounds.height))
                .aspectRatio(contentMode: .fit)
                .frame(width: bounds.width, height: bounds.height)
                .toErasedView()
        } else if let nsImage = NSImage(data: data) {
            view = Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: bounds.width, height: bounds.height)
                .toErasedView()
        } else {
            view = makeErrorView("This image is not valid", frame: bounds)
                .toErasedView()
        }
        
        return view
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
    }
    
    private func makeErrorView(_ error: String, frame: CGSize) -> some View {
        VStack(alignment: .center) {
            Image(systemName: "exclamationmark.circle")
                .imageScale(.large)
            
            Text("\(asset.filename)\(asset.extension)")
                .font(.footnote)
        }
        .help(error)
        .frame(width: frame.width, height: frame.height)
    }
    
    func load() {
        if viewModel.state == .empty {
            self.viewModel.state = .loading
            self.viewModel.pending = dataProvider.getImage(for: asset, completion: handleCompletion)
        }
    }
    
    private func handleSaveImage() {
        guard let data = viewModel.imageData else { return }
        
        let result = DataManager.shared.saveImageData(
            fileName: asset.fullName,
            data: data,
            to: saveLocation)
        
        switch result {
        case .success:
            viewModel.popoverMessage = "Saved \(asset.fullName) to \(saveLocation.path)"
            viewModel.popoverType = .success
            
            // dismiss the popover after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                viewModel.popoverMessage = nil
                viewModel.popoverType = nil
            }
            
        case .failure(let error):
            viewModel.popoverMessage = error.localizedDescription
            viewModel.popoverType = .error
        }
    }
    
    private func getBounds() -> CGSize {
        if let bounds = self.bounds {
            return bounds
        }
        
        return CGSize(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
    }
    
    private func handleCompletion(_ result: Result<Data, Error>) {
        switch result {
        case .success(let data):
            // save the data regardless if it is something we can render
            viewModel.imageData = data
            self.viewModel.state = .done(data)
            
        case .failure(let error):
            print(error)
            self.viewModel.state = .error(error.localizedDescription)
        }
    }
}

// MARK: - View Model

class WebImageViewModel: ObservableObject {
    @Published var pending: AnyCancellable?
    @Published var state: State = .empty
    @Published var imageData: Data?
    @Published var popoverType: PopoverType?
    @Published var popoverMessage: String?
    
    enum PopoverType: Identifiable {
        var id: Int { hashValue }
        
        case success
        case error
    }
    
    enum State: Equatable {
        case empty
        case loading
        case error(String)
        case done(Data)
    }
}

// MARK: - Previews

struct WebImage_Previews: PreviewProvider {
    static var previews: some View {
        WebImage(Asset(
                    id: 1594686780709,
                    boardId: "g",
                    width: 100,
                    height: 50,
                    thumbnailWidth: 100,
                    thumbnailHeight: 50,
                    filename: "lol",
                    extension: ".jpg",
                    fileType: .image),
                 saveLocation: URL(fileURLWithPath: "/foo"),
                 bounds: CGSize(width: 128.0, height: 128.0),
                 onOpen: { _ in })
    }
}
