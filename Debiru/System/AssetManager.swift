//
//  AssetManager.swift
//  Debiru
//
//  Created by Mike Polan on 7/29/24.
//

// MARK: - Models

/// Enumeration of possible results for asset management operations.
enum AssetResult {
    case success
    case denied
    case error(message: String)
}

// MARK: - iOS

#if os(iOS)

import Photos
import UIKit

/// A service that manages the creation of new assets.
struct AssetManager {
    private static let albumName = "Debiru Images"
    private static var shared: AssetManager?
    
    /// Saves an image or media asset to the user's photo library.
    ///
    /// - Parameter fileName: The filename of the asset.
    /// - Parameter data: The raw data of the asset.
    ///
    /// - Returns: A result indicating the outcome of the operation.
    func saveImage(fileName: String, data: Data) async -> AssetResult {
        do {
            guard await hasAccess(), let album = try await getOrCreateAlbum() else {
                return .denied
            }
            
            guard let image = UIImage(data: data) else {
                return .error(message: "Invalid image data")
            }
            
            try await PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
            })
            
            return .success
        } catch {
            return .error(message: error.localizedDescription)
        }
    }
    
    /// Returns or creates the default album for the app.
    ///
    /// - Returns: The photo library collection representing the album.
    private func getOrCreateAlbum() async throws -> PHAssetCollection? {
        guard let album = getAlbum() else {
            try await createAlbum()
            return getAlbum()
        }
        
        return album
    }
    
    /// Creates the default album for the app.
    private func createAlbum() async throws {
        try await PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
        })
    }
    
    /// Returns the default album for the app.
    ///
    /// - Returns: A photo library collection representing the album, or nil if it does not exist,
    private func getAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", Self.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        return collection.firstObject
    }
    
    /// Requests authorization from the user to perform read/write operations on their photo library.
    ///
    /// - Returns: A boolean indicating if the user allowed access.
    private func hasAccess() async -> Bool {
        let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return result == .authorized || result == .limited
    }
}

#endif
