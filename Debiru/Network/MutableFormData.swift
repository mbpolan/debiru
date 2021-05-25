//
//  MutableFormData.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import Foundation

class MutableFormData {
    private var body: String
    private let boundary: String
    
    init(boundary: String = "boundary-\(UUID().uuidString)") {
        self.boundary = boundary
        self.body = ""
    }
    
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    var data: Data? {
        (body + "--\(boundary)--").data(using: .utf8)
    }
    
    func addField(_ key: String, value: String?) {
        guard let value = value else { return }
        
        var field = "--\(boundary)\r\n"
        field += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
        field += "\(value)\r\n"
        
        body += field
    }
}
