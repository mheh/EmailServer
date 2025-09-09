//
//  EmailServerAPI.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import SwiftMail
import Logging


extension SMTPSessions {
    public actor Connection {
        /// The address and port to connect to
        public let configuration : Connection.Configuration
        
        /// Login Information that was used if we want to try to reauthenticate
        private var loginInformation: Connection.LoginInformation? = nil
        
        /// The server to communicate with
        private let server: SwiftMail.SMTPServer
        
        private let logger: Logger
        
        public init(
            configuration: Connection.Configuration,
            logger: Logger = .init(label: "SMTP Connection")
        ) {
            self.configuration = configuration
            self.server = .init(host: configuration.host, port: configuration.port, numberOfThreads: configuration.numberOfThreads)
            self.logger = logger
        }
        
        public init(
            configuration: Connection.Configuration,
            server: SwiftMail.SMTPServer,
            logger: Logger = .init(label: "SMTP Connection")
        ) {
            self.configuration = configuration
            self.server = server
            self.logger = logger
        }
    }
}

extension SMTPSessions.Connection {
    public func connect() async throws {
        try await self.server.connect()
    }
    
    public func login(username: String, password: String) async throws {
        try await self.server.login(username: username, password: password)
        self.loginInformation = .init(username: username, password: password)
    }
    
    public func fetchCapabilities() async throws -> [String] {
        return try await self.server.fetchCapabilities()
    }
    
    public func send(_ email: SwiftMail.Email) async throws {
        try await self.server.sendEmail(email)
    }
    
    public func disconnect() async throws {
        try await self.server.disconnect()
    }
}


extension SMTPSessions.Connection {
    public struct Configuration: Codable {
        public let host: String
        public let port: Int
        public let numberOfThreads: Int
        
        /// Do we need host validation per `RFC 5432, section 2.3.4 and 2.3.5`?
        /// Marked throwing as a precaution.
        public init(host: String, port: Int, numberOfThreads: Int = 1) {
            self.host = host
            self.port = port
            self.numberOfThreads = numberOfThreads
        }
    }
    
    /// Saved login information
    public struct LoginInformation: Codable {
        private let username: String
        private let password: String
        
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }
    
    public enum ConnectionError: Error {
        case noLoginInformation
    }
}
