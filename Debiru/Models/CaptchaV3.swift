//
//  CaptchaV3.swift
//  Debiru
//
//  Created by Mike Polan on 11/27/22.
//

import Foundation

struct CaptchaV3Challenge {
    let twister: CaptchaV3Twister?
}

struct CaptchaV3Twister {
    let challenge: String
    let image: Data
    let background: Data
    let imageSize: CGSize
    let backgroundSize: CGSize
}
