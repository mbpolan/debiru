//
//  String.swift
//  Debiru
//
//  Created by Mike Polan on 4/17/21.
//

import Foundation
import SwiftSoup

extension String {
    /// Unescapes HTML entities embedded in the string.
    ///
    /// - Returns: A new string with HTML entities unescaped.
    func unescapeHTML() -> String {
        return CFXMLCreateStringByUnescapingEntities(nil, self as CFString, nil) as String
    }
    
    /// Removes all HTML tags from the string.
    ///
    /// Errors are handled internally; if a string cannot be parsed, the original
    /// string is returned as-is.
    ///
    /// - Returns: A new string without any HTML tags or structures.
    func removeHTML() -> String {
        do {
            return try SwiftSoup.clean(self, Whitelist.none()) ?? self
        } catch (let error) {
            print("Failed to sanitize HTML: \(error.localizedDescription)")
            return self
        }
    }
}
