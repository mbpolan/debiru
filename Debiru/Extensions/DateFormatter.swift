//
//  DateFormatter.swift
//  Debiru
//
//  Created by Mike Polan on 3/28/21.
//

import Foundation

extension DateFormatter {
    static func standard() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        
        return dateFormatter
    }
}
