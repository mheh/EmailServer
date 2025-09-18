//
//  Application+SMTPEmailRepository.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor

extension Application {
    var smtpEmails: SMTPEmailRepository {
        get {
            guard let repository = self.storage[SMTPEmailRepositoryStorage.self] else {
                fatalError("SMTP Email Repository not initialized")
            }
            return repository
        }
        set {
            self.storage[SMTPEmailRepositoryStorage.self] = newValue
        }
    }
    
    struct SMTPEmailRepositoryStorage: StorageKey {
        typealias Value = SMTPEmailRepository
    }
}

extension Request {
    var smtpEmails: SMTPEmailRepository {
        get {
            return self.application.smtpEmails
        }
    }
}
