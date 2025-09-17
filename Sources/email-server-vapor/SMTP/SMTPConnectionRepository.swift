//
//  Websocket+SMTPRepository.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/14/25.
//

import Vapor
import EmailServerAPI
import SwiftMail

actor SMTPConnectionRepository {
    /// A store of active connections and credentials
    private var activeConnections: [UUID: ActiveConnection]
    
    /// Cleanup task of unused connections.
    private var cleanupTask: Task<Void, any Error>?
    
    var logger: Logger
    
    init(
        logger: Logger = .init(label: "SMTP Connection Repository"),
        logLevel: Logger.Level = .debug
    ) {
        self.activeConnections = [:]
        self.logger = logger
        self.logger.logLevel = logLevel
        self.cleanupTask = nil
    }
    
    /// Create a new active SMTP connection
    func new(
        host: String, port: Int,
        username: String, password: String
    ) async throws -> UUID {
        let id = UUID()
        let newActiveConnection = try await ActiveConnection(
            connectionDetails: .init(
                host: host,
                port: port,
                username: username,
                password: password),
            )
        self.activeConnections[id] = newActiveConnection
        return id
    }
    
    func find(id: UUID) -> ActiveConnection? {
        guard let found = self.activeConnections[id] else {
            return nil
        }
        
        return found
    }
    
    public func startCleanupTask() {
        self.cleanupTask = Task {
            
            while !Task.isCancelled {
                // sleep for 1 minute each cycle
                try await Task.sleep(for: .seconds(Constants.Time.ONE_MINUTE))
                for (id, activeConnection) in self.activeConnections {
                    
                    // if our lastUsedAt is older than 1 minute, needs removal
                    guard await activeConnection.lastUsedAt
                        .addingTimeInterval(Constants.Time.ONE_MINUTE) >= Date()
                    else {
                        continue
                    }
                    
                    // remove
                    self.activeConnections.removeValue(forKey: id)
                    try await activeConnection.server.disconnect()
                }
            }
            
        }
    }
    
    /// An active SMTP connection
    actor ActiveConnection {
        let createdAt: Date
        var lastUsedAt: Date
        let connectionDetails: ConnectionDetails
        let server: SMTPServer
        var logger: Logger
        
        init(
            createdAt: Date = Date(),
            lastUsedAt: Date = Date(),
            connectionDetails: ConnectionDetails,
            logger: Logger = .init(label: "SMTP Active Connection"),
            logLevel: Logger.Level = .debug
        ) async throws {
            self.logger = logger
            self.logger.logLevel = logLevel
            self.createdAt = createdAt
            self.lastUsedAt = lastUsedAt
            self.connectionDetails = connectionDetails
            let connectionMetadata = await self.connectionDetails.metadata()
            
            self.server = .init(
                host: connectionDetails.host,
                port: connectionDetails.port,
                numberOfThreads: 1
            )
            do {
                try await self.server.connect()
            } catch {
                self.logger.debug("Failed to connect to SMTP server", metadata: connectionMetadata)
                throw error
            }
            do {
                try await self.server.login(
                    username: connectionDetails.username,
                    password: connectionDetails.password)
            } catch {
                self.logger.debug("Failed to login to SMTP server", metadata: connectionMetadata)
                throw error
            }
        }
        
        func wasUsed() {
            self.lastUsedAt = Date()
        }
    }
    
    /// The connection details to use for an open SMTP connection
    actor ConnectionDetails {
        let host: String
        let port: Int
        let username: String
        let password: String
        
        public func metadata() -> Logger.Metadata {
            return [
                "host":"\(self.host)",
                "port": "\(self.port)"
            ]
        }

        init(
            host: String,
            port: Int,
            username: String,
            password: String
        ) {
            self.host = host
            self.port = port
            self.username = username
            self.password = password
        }
    }
}
