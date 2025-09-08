//
//  EmailServerAPI.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import SwiftMail
import Logging

public actor SMTPConnection {
    public let sessionId: UUID
    public let configuration : SMTPConnection.Configuration
    private var loginInformation: SMTPConnection.LoginInformation? = nil
    
    public let server: SwiftMail.SMTPServer
    
    public let logger: Logger
    
    public init(
        sessionId: UUID = UUID(),
        configuration: SMTPConnection.Configuration,
        logger: Logger = .init(label: "SMTP Connection")
    ) {
        self.sessionId = sessionId
        self.configuration = configuration
        self.server = .init(host: configuration.host, port: configuration.port, numberOfThreads: configuration.numberOfThreads)
        self.logger = logger
    }
    
    public init(
        sessionId: UUID,
        configuration: SMTPConnection.Configuration,
        server: SwiftMail.SMTPServer,
        logger: Logger = .init(label: "SMTP Connection")
    ) {
        self.sessionId = sessionId
        self.configuration = configuration
        self.server = server
        self.logger = logger
    }
    
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
    
    /// If previously successfully authenticated, try to authenticate again.
    public func reauthenticate(reconnect: Bool = false) async throws {
        guard let loginInformation else {
            throw SMTPConnection.ConnectionError.noLoginInformation
        }
        
        if reconnect {
            try await self.server.connect()
        }
        try await self.server.login(username: loginInformation.username, password: loginInformation.password)
    }
}

extension SMTPConnection {
    public struct Configuration: Codable {
        public let host: String
        public let port: Int
        public let numberOfThreads: Int
        
        /// Do we need host validation per `RFC 5432, section 2.3.4 and 2.3.5`?
        /// Marked throwing as a precaution.
        public init(host: String, port: Int, numberOfThreads: Int = 1) throws {
            self.host = host
            self.port = port
            self.numberOfThreads = numberOfThreads
        }
    }
    
    public struct LoginInformation: Codable {
        public let username: String
        public let password: String
        
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }
    
    public enum ConnectionError: Error {
        case noLoginInformation
    }
}
