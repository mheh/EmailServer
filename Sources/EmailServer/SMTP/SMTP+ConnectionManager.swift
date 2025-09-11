////
////  ConnectionManager.swift
////  EmailServer
////
////  Created by Milo Hehmsoth on 9/8/25.
////
//
//#if canImport(FoundationEssentials)
//import FoundationEssentials
//#else
//import Foundation
//#endif
//
///// The owner of all current `SMTP` connections
//public actor SMTPSessions {
//    /// Active sessions
//    private var sessions: [UUID: Connection]
//    
//    public init() {
//        self.sessions = [:]
//    }
//}
//
//extension SMTPSessions {
//    public func find(sessionId: UUID) throws -> SMTPSessions.Connection {
//        guard let session = self.sessions[sessionId] else {
//            throw ManagerError.sessionIdNotFound
//        }
//        
//        return session
//    }
//}
//
//extension SMTPSessions {
//    public func new(host: String, port: Int) -> (sessionId: UUID, connection: SMTPSessions.Connection) {
//        let newSessionId = UUID()
//        let newConnection = SMTPSessions.Connection(
//            configuration: .init(host: host, port: port),
//            logger: .init(label: "SMTP Connection \(newSessionId.uuidString)"))
//        self.sessions[newSessionId] = newConnection
//
//        return (newSessionId, newConnection)
//    }
//    
//    public func close(sessionId: UUID) throws {
//        guard let index = self.sessions.firstIndex(where: {$0.key == sessionId}) else {
//            throw ManagerError.sessionIdNotFound
//        }
//        self.sessions.remove(at: index)
//    }
//}
//
//// MARK: State Management & Cleanup
//extension SMTPSessions {
//    
//}
//
//// MARK: Errors
//extension SMTPSessions {
//    enum ManagerError: Error {
//        /// The requested sessionId was not found in local state
//        case sessionIdNotFound
//        /// The session already exists
//        case sessionAlreadyExists
//    }
//}
