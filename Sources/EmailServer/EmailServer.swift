//
//  EmailServer.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import EmailClients
import SwiftMCP

@MCPServer(name: "EmailServer")
actor EmailServer {
    let smtpSessions: SMTPSessions = .init()
    
    @MCPTool(description: "Get a new SMTP session")
    func newSMTPSession(host: String, port: Int, username: String, password: String) async throws -> UUID {
        let (sessionId, connection) = await self.smtpSessions.new(host: host, port: port)
        try await connection.connect()
        try await connection.login(username: username, password: password)
        
        return sessionId
    }
    
    @MCPTool(description: "Send a SMTP email with no attachments for a session")
    func send(sessionId: UUID, email: SMTPSessions.Connection.Email) async throws {
        let found = try await self.smtpSessions.find(sessionId: sessionId)
        try await found.send(email)
    }
    
    @MCPTool(description: "Close an active SMTP session")
    func close(sessionId: UUID) async throws {
        try await self.smtpSessions.close(sessionId: sessionId)
    }
}
