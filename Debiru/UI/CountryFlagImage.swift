//
//  CountryFlagImage.swift
//  Debiru
//
//  Created by Mike Polan on 4/18/21.
//

import Combine
import SwiftUI

// MARK: - View

struct CountryFlagImage: View {
    @StateObject private var viewModel: CountryFlagImageViewModel = CountryFlagImageViewModel()
    private(set) var code: String
    private(set) var name: String
    private(set) var dataProvider: DataProvider = FourChanDataProvider()
    
    var body: some View {
        makeImage()
            .help(name)
            .task(handleLoadImage)
    }
    
    private func makeImage() -> AnyView {
        let view: AnyView
        
        switch viewModel.state {
        case .loading:
            view = ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .toErasedView()
            
        case .error(_):
            view = Image(systemName: "exclamationmark.circle")
                .toErasedView()
            
        case .success:
            if let image = viewModel.image {
                view = PFMakeImage(image)
                    .toErasedView()
            } else {
                view = Image(systemName: "exclamationmark.circle")
                    .toErasedView()
            }
        }
        
        return view
    }
    
    @Sendable private func handleLoadImage() async {
        viewModel.state = .loading
        
        do {
            let data = try await dataProvider.getCountryFlagImage(for: code)
            if let data = data,
               let image = PFImage(data: data) {
                viewModel.state = .success
                viewModel.image = image
            } else {
                viewModel.state = .error("Invalid image")
            }
        } catch {
            viewModel.state = .error(error.localizedDescription)
        }
    }
}

// MARK: - View Model

class CountryFlagImageViewModel: ObservableObject {
    @Published var image: PFImage?
    @Published var state: ImageState = .loading
    @Published var pendingImage: AnyCancellable?
    
    enum ImageState {
        case loading
        case error(String)
        case success
    }
}

// MARK: - Previews

struct CountryFlagImage_Previews: PreviewProvider {
    static var previews: some View {
        CountryFlagImage(
            code: "EU",
            name: "Europe")
    }
}
