//
//  EmailServer.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import Logging
import SwiftMail
import SwiftMCP

@MCPServer(name: "EmailServer")
actor EmailServer {
    let logger: Logger = .init(label: "EmailServer")
    
    @MCPTool(description: "Send a SMTP email with no attachments for a session")
    func send(
        host: String, port: Int
    ) async throws {
        let smtpConnection = SwiftMail.SMTPServer(host: host, port: port)
        try await smtpConnection.connect()
      
        await Session.current?.sendLogNotification(LogMessage(level: .info, data: "send email called"))
        
        // create a connection object
        let loginSchema = JSONSchema.object(JSONSchema.Object(
            properties: [
                "username": .string(title: "Username", description: "The username to connect with", format: nil, minLength: 3, maxLength: 50),
                "password": .string(title: "Password", description: "The password to connect with", format: nil, minLength: nil, maxLength: nil)
            ],
            required: ["username", "password"],
            title: "Connect to the SMTP server",
            description: "Provide credentials to establish an SMTP server connection"
        ))
        
        let loginResponse = try await RequestContext.current.elicit(message: "Please login with your credentials", schema: loginSchema)
        guard loginResponse.action == .accept,
              let content = loginResponse.content,
              let username = content["username"]?.value as? String,
              let password = content["password"]?.value as? String else {
            return try await smtpConnection.disconnect()
        }
        do {
            try await smtpConnection.login(username: username, password: password)
            await Session.current.sendLogNotification(.init(level: .info, data: "Login succeeded!"))
        } catch {
            await Session.current.sendLogNotification(.init(level: .error, data: "Login failed: \(error)"))
            return try await smtpConnection.disconnect()
        }

        return try await smtpConnection.disconnect()
    }
    
    @MCPTool(description: "Connect to imap and issue commands")
    func imapConnect(
        host: String, port: Int,
        username: String, password: String
    ) async throws {
//        Session.current.
        let imapConnection = SwiftMail.IMAPServer(host: host, port: port)
        try await imapConnection.connect()
        try await imapConnection.login(username: username, password: password)
        
        let idleStream = try await imapConnection.idle()
        
        
        
        for await event in idleStream {
            switch event {
                
            case .exists(let currentMessageCount):
                self.logger.info("Current message count: \(currentMessageCount)")
            case .expunge(let sequenceNumber):
                self.logger.info("Sequence number: \(sequenceNumber)")
            case .recent(let recentMessages):
                self.logger.info("Recent message count: \(recentMessages)")
            case .fetch(let sequenceNumber, let messageAttributes):
                self.logger.info("Sequence number: \(sequenceNumber)")
                for messageAttribute in messageAttributes {
                    self.logger.info("Message attribute: \(messageAttribute.debugDescription)")
                }
            case .alert(let alert):
                self.logger.info("Alert: \(alert)")
            case .capability(let capabilities):
                self.logger.info("Capabilities")
                capabilities.forEach { self.logger.info("Capability: \($0)")}
            case .bye(let bye):
                if let bye {
                    self.logger.info("Bye received: \(bye)")
                } else {
                    self.logger.info("Bye received")
                }
            }
        }
        
    }
    
    /**
     Requests basic contact information from the user using the MCP Elicitation feature.
     - Returns: A string describing the user's response or the action they took
     */
    @MCPTool(description: "Requests contact information from the user")
    func requestContactInfo() async throws -> String {
        await Session.current?.sendLogNotification(LogMessage(level: .info, data: [
            "function": "requestContactInfo",
            "message": "requestContactInfo called"
        ]))
        
        // Create a schema for contact information
        let schema = JSONSchema.object(JSONSchema.Object(
            properties: [
                "name": .string(title: "Full Name", description: "Your full name", format: nil, minLength: 2, maxLength: 50),
                "email": .string(title: "Email Address", description: "Your email address", format: "email", minLength: nil, maxLength: nil),
                "age": .number(title: "Age", description: "Your age", minimum: 13, maximum: 120)
            ],
            required: ["name", "email"],
            title: "Contact Information",
            description: "Basic contact details"
        ))
        
        let response = try await RequestContext.current?.elicit(
            message: "Please provide your contact information",
            schema: schema
        )
        
        guard let elicitationResponse = response else {
            return "No elicitation response received"
        }
        
        switch elicitationResponse.action {
        case .accept:
            if let content = elicitationResponse.content {
                let name = content["name"]?.value as? String ?? "Unknown"
                let email = content["email"]?.value as? String ?? "Unknown"
                let age = content["age"]?.value as? Double ?? 0
                return "Thank you! Contact info received: \(name) (\(email)), age: \(Int(age))"
            } else {
                return "User accepted but no content was provided"
            }
        case .decline:
            return "User declined to provide contact information"
        case .cancel:
            return "User cancelled the contact information request"
        }
    }
}
