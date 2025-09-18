//
//  Application+SMTPConnectionRepository.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor

extension Application {
    /// Manage smtp connection states
    var smtp: SMTPConnectionRepository {
        get {
            guard let repository = self.storage[SMTPRepositoryStorage.self] else {
                fatalError("SMTP Connection Repository not initialized")
            }
            return repository
        }
        set {
            self.storage[SMTPRepositoryStorage.self] = newValue
        }
    }
    
    struct SMTPRepositoryStorage: StorageKey {
        typealias Value = SMTPConnectionRepository
    }
}

extension Request {
    var smtp: SMTPConnectionRepository {
        get {
            return self.application.smtp
        }
    }
}
