//
//  MutableFormData.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import Foundation

class MutableFormData {
    private var body: NSMutableData
    private let boundary: String
    
    init(boundary: String = "boundary-\(UUID().uuidString)") {
        self.boundary = boundary
        self.body = NSMutableData()
    }
    
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    func build() -> Data {
        addString("--\(boundary)--")
        return body as Data
    }
    
    func addField(_ key: String, value: String?) {
        guard let value = value else { return }
        
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
        field += "\(value)\r\n"
        
        addString(field)
    }
    
    func addFile(_ key: String, fileName: String, value: Data?) {
        guard let value = value else { return }
        let contentType = determineContentType(of: value)
        
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n"
        field += "Content-Type: \(contentType)\r\n\r\n"
        
        addString(field)
        body.append(value)
        addString("\r\n")
    }
    
    private func addString(_ value: String) {
        if let data = value.data(using: .utf8) {
            body.append(data)
        }
    }
    
    private func determineContentType(of data: Data) -> String {
        var header: UInt8 = 0
        data.copyBytes(to: &header, count: 1)
        
        switch header {
        case 0x47:
            return "image/gif"
        case 0x89:
            return "image/jpeg"
        case 0xFF:
            return "image/png"
        default:
            return "application/octet-stream"
        }
    }
}
