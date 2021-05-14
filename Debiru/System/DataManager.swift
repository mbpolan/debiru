//
//  DataManager.swift
//  Debiru
//
//  Created by Mike Polan on 5/14/21.
//

import SwiftUI

struct DataManager {
    static let shared: DataManager = DataManager()
    
    func saveImageData(fileName: String, data: Data, to url: URL) -> Result<Void, Error> {
        guard !url.startAccessingSecurityScopedResource() else {
            return .failure(DataError.noPermission)
        }
        
        let result: Result<Void, Error>
        do {
            // create the directory path if it doesn't already exist
            var isDirectory: ObjCBool = true
            if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: false,
                    attributes: nil)
            }
            
            // write the image with its filename preserved
            try data.write(to: url.appendingPathComponent(fileName))
            
            result = .success(())
        } catch (let error) {
            result = .failure(error)
        }
        
        url.stopAccessingSecurityScopedResource()
        return result
    }
    
    func checkSaveDirectory() -> Result<Void, Error> {
        guard let bookmark = UserDefaults.standard.data(forKey: StorageKeys.bookmarkSaveDirectory) else {
            return .failure(DataError.noSaveDirectoryDefined)
        }
        
        do {
            var stale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                bookmarkDataIsStale: &stale)
            
            if stale {
                return bookmarkSaveDirectory(url)
            }
            
            return .success(())
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func bookmarkSaveDirectory(_ url: URL) -> Result<Void, Error> {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil)
            
            UserDefaults.standard.set(data, forKey: StorageKeys.bookmarkSaveDirectory)
            
            return .success(())
        } catch (let error) {
            return .failure(error)
        }
    }
}

extension DataManager {
    enum DataError: Error, LocalizedError {
        case noSaveDirectoryDefined
        case noPermission
        
        var errorDescription: String? {
            switch self {
            case .noSaveDirectoryDefined:
                return NSLocalizedString("No save directory has been defined in app preferences", comment: "")
            case .noPermission:
                return NSLocalizedString("Permission has not been given to save files to the data directory", comment: "")
            }
        }
    }
}
