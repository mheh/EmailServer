//
//  Constants.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Foundation

enum Constants {
    enum Time {
        static let FIVE_SECONDS: Double = 5
        static let TEN_SECONDS: Double = 10
        static let THIRTY_SECONDS: Double = 30
        static let ONE_MINUTE: Double = 60
        static let FIVE_MINUTES: Double = 60 * 5
        
        static let SMTP_EMAIL_BATCH_CLEAN: Double = FIVE_SECONDS
        static let SMTP_CONNECTION_CLEAN: Double = TEN_SECONDS
    }
}
