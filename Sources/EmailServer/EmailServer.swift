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
    
    @MCPTool(description: "Get a new SMTP session")
    func newSMTPSession() async throws -> UUID {
        return UUID()
    }
    
    func sendEmail(email: Email) async throws {
        
    }
}
