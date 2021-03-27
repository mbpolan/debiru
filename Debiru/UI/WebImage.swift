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
    
    init(_ asset: Asset, saveLocation: URL, bounds: CGSize? = nil) {
        self.asset = asset
        self.saveLocation = saveLocation
        self.bounds = bounds
    }
    
    var body: some View {
        let frame = getBounds()
        
        Group {
            switch viewModel.state {
            case .done(let image):
                makeImage(image)
                
            case .error(let error):
                VStack(alignment: .center) {
                    Image(systemName: "exclamationmark.circle")
                        .imageScale(.large)
                    
                    Text("\(asset.filename)\(asset.extension)")
                        .font(.footnote)
                }
                .help(error)
                .frame(width: frame.width, height: frame.height)
                
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
        .onAppear(perform: self.load)
    }
    
    func load() {
        if viewModel.state == .empty {
            self.viewModel.state = .loading
            self.viewModel.pending = dataProvider.getImage(for: asset, completion: handleCompletion)
        }
    }
    
    private func handleSaveImage() {
        if let data = viewModel.imageData {
            do {
                // default to the user's pictures directory
                try data.write(to: saveLocation.appendingPathComponent(asset.fullName))
                
                viewModel.popoverMessage = "Saved \(asset.fullName) to \(saveLocation.path)"
                viewModel.popoverType = .success
                
                // dismiss the popover after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    viewModel.popoverMessage = nil
                    viewModel.popoverType = nil
                }
            } catch (let error) {
                viewModel.popoverMessage = error.localizedDescription
                viewModel.popoverType = .error
            }
        }
    }
    
    private func getBounds() -> CGSize {
        if let bounds = self.bounds {
            return bounds
        }
        
        return CGSize(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight))
    }
    
    private func makeImage(_ nsImage: NSImage) -> some View {
        let image = Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
        
        let result: AnyView
        if let bounds = self.bounds {
            result = AnyView(
                image
                    .clipShape(RoundedRectangle(cornerRadius: 5.0))
                    .frame(width: bounds.width, height: bounds.height))
        } else {
            result = AnyView(
                image
                    .frame(width: CGFloat(asset.thumbnailWidth), height: CGFloat(asset.thumbnailHeight)))
        }
        
        return result
    }
    
    private func handleCompletion(_ result: Result<Data, Error>) {
        switch result {
        case .success(let data):
            // save the data regardless if it is something we can render
            viewModel.imageData = data
            
            if let image = NSImage(data: data) {
                self.viewModel.state = .done(image)
            } else {
                self.viewModel.state = .error("This image is not valid")
            }
            
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
        case done(NSImage)
    }
}
