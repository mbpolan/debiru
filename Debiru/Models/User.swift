//
//  User.swift
//  Debiru
//
//  Created by Mike Polan on 3/28/21.
//

struct User: Hashable, Codable {
    let name: String?
    let tripCode: String?
    let isSecure: Bool
    let tag: Tag?
    let country: Country?
}

extension User {
    enum Tag: String, Codable {
        case administrator
        case moderator
        case manager
        case developer
        case founder
        case verified
    }
    
    enum Country: Equatable, Hashable, Codable {
        case code(code: String, name: String)
        case fake(code: String, name: String)
        case unknown
    }
}

extension User.Country {
    private enum CodingKeys: CodingKey {
        case code
        case fake
        case unknown
    }
    
    private struct CountryData: Codable {
        let code: String
        let name: String
    }
    
    private struct FakeCountryData: Codable {
        let fakeCode: String
        let fakeName: String
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let data = try? values.decode(CountryData.self, forKey: .code) {
            self = .code(code: data.code, name: data.name)
        } else if let data = try? values.decode(FakeCountryData.self, forKey: .code) {
            self = .fake(code: data.fakeCode, name: data.fakeName)
        } else {
            self = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .code(let code, let name):
            try container.encode(CountryData(code: code, name: name), forKey: .code)
        case .fake(let code, let name):
            try container.encode(FakeCountryData(fakeCode: code, fakeName: name), forKey: .code)
        case .unknown:
            try container.encodeNil(forKey: .unknown)
        }
    }
}
