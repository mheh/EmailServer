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
    
    func startCleanupTask() {
        self.cleanupTask = Task {
            while !Task.isCancelled {
                // sleep for 1 minute each cycle
                try await Task.sleep(for: .seconds(Constants.Time.SMTP_CONNECTION_CLEAN))
                
                if !self.activeConnections.isEmpty {
                    logger.info("Cleaning", metadata: metadata())
                }
                
                for (id, activeConnection) in self.activeConnections {
                    // check expiration
                    guard await activeConnection.isExpired else { continue }
                    
                    // remove
                    self.activeConnections.removeValue(forKey: id)
                    await activeConnection.disconnect()
                }
            }
        }
    }
    
    func metadata() -> Logger.Metadata {
        var metadata: Logger.Metadata = [
            "connections":"\(self.activeConnections.count)",
            "cleanup_task_exists":"\(self.cleanupTask != nil ? "false" : "true")",
        ]
        if let cleanupTask {
            metadata["cleanup_task_is_cancelled"] = "\(cleanupTask.isCancelled)"
        }
        
        return metadata
    }
}

extension SMTPConnectionRepository {
    /// An active SMTP connection
    actor ActiveConnection {
        let createdAt: Date
        var lastUsedAt: Date
        var isExpired: Bool {
            self.lastUsedAt
                .addingTimeInterval(Constants.Time.ONE_MINUTE) >= Date()
        }
        let connectionDetails: ConnectionDetails
        private let server: SMTPServer
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
            let metadata = Self.metadata(details: connectionDetails, createdAt: self.createdAt, lastUsedAt: self.lastUsedAt)
            
            self.server = .init(
                host: connectionDetails.host,
                port: connectionDetails.port,
                numberOfThreads: 1
            )
            do {
                try await self.server.connect()
            } catch {
                let metadataWithError = Self.metadata(metadata: metadata, error: error)
                self.logger.error("Failed to connect", metadata: metadataWithError)
                throw error
            }
            do {
                try await self.server.login(
                    username: connectionDetails.username,
                    password: connectionDetails.password)
            } catch {
                let metadataWithError = Self.metadata(metadata: metadata, error: error)
                self.logger.error("Failed to login", metadata: metadataWithError)
                throw error
            }
            
            // wow holy shit i can do self.log in the initializer somehow. this feels illegal
            self.log("Created connection")
        }
        
        func send(email: SwiftMail.Email) async {
            do {
                try await self.server.sendEmail(email)
                self.log("Sent")
            } catch {
                self.log("Couldn't send email", error)
            }
            self.wasUsed()
        }
        
        /// Disconnect from the server for cleanup
        func disconnect() async {
            do {
                try await self.server.disconnect()
                self.log("Disconnected")
            } catch {
                self.log("Error disconnecting", error)
            }
        }
        
        /// Update `self.lastUsedAt` to prolong life
        func wasUsed() {
            self.lastUsedAt = Date()
            self.log(logLevel: .trace, "Was used")
        }
    }
}

// MARK: - Logging (ActiveConnection)
extension SMTPConnectionRepository.ActiveConnection {
    func log(logLevel: Logger.Level = .debug, _ message: Logger.Message, _ error: (any Error)? = nil) {
        let metadata = Self.metadata(
            details: self.connectionDetails,
            createdAt: self.createdAt,
            lastUsedAt: self.lastUsedAt
        )
        guard let error else {
            return self.logger.log(level: logLevel, message, metadata: metadata)
        }
        let metadataWithError = Self.metadata(metadata: metadata, error: error)
        return self.logger.error(message, metadata: metadataWithError)
    }
    
    
    static func metadata(metadata: Logger.Metadata, error: any Error) -> Logger.Metadata {
        var metadata = metadata
        metadata["error"] = "\(error)"
        metadata["error_description"] = "\(error.localizedDescription)"
        return metadata
    }
    
    static func metadata(
        details: ConnectionDetails,
        createdAt: Date,
        lastUsedAt: Date
    ) -> Logger.Metadata {
        let connectionMetadata = details.metadata()
        let metadata: Logger.Metadata = [
            "created_at":"\(createdAt)",
            "last_used_at":"\(lastUsedAt)"
        ]
        return metadata.merging(connectionMetadata, uniquingKeysWith: {original, connectionMetadata in
            return original
        })
    }
}

extension SMTPConnectionRepository.ActiveConnection {
    /// The connection details to use for an open SMTP connection
    struct ConnectionDetails {
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
