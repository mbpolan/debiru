//
//  Submission.swift
//  Debiru
//
//  Created by Mike Polan on 5/24/21.
//

import Foundation

struct Submission {
    let replyTo: Int?
    let name: String?
    let asset: AssetSubmission?
    let bump: Bool
    let content: String
    let captchaToken: String
}

struct AssetSubmission {
    let data: Data
    let fileName: String
}

enum SubmissionResult {
    case success(postId: Int)
    case indeterminate
    case failure(Error)
}
