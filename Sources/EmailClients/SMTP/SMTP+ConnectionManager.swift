//
//  ConnectionManager.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The owner of all current `SMTP` connections
public actor SMTPConnectionManager {
    
    private var connections: [UUID: SMTPConnection]
    
    public init() {
        self.connections = [:]
    }
}

extension SMTPConnectionManager {
    public func find(sessionId: UUID) throws -> SMTPConnection {
        guard let connection = self.connections[sessionId] else {
            throw ManagerError.sessionIdNotFound
        }
        
        return connection
    }
}

extension SMTPConnectionManager {
    public func newSession(host: String, port: Int) throws -> (sessionId: UUID, connection: SMTPConnection) {
        let newConnection = SMTPConnection(configuration: .init(host: host, port: port))

        let newSessionId = UUID()
        self.connections[newSessionId] = newConnection

        return (newSessionId, newConnection)
    }
    
    public func close(sessionId: UUID) throws {
        guard let index = self.connections.firstIndex(where: {$0.key == sessionId}) else {
            throw ManagerError.sessionIdNotFound
        }
        self.connections.remove(at: index)
    }
}

// MARK: State Management
extension SMTPConnectionManager {
    
}

// MARK: Errors
extension SMTPConnectionManager {
    enum ManagerError: Error {
        /// The requested sessionId was not found in local state
        case sessionIdNotFound
        /// The session already exists
        case sessionAlreadyExists
    }
}
