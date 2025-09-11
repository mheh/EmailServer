//
//  Server.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor
import OpenAPIVapor
import EmailServerAPI
import Logging
import NIOCore
import NIOPosix

struct Handler: APIProtocol, @unchecked Sendable {
    @Injected(\.request) var req: Request
    
    let smtpStreamController = SMTPStreamController()
    func smtpStream(_ input: EmailServerAPI.Operations.SmtpStream.Input) async throws -> EmailServerAPI.Operations.SmtpStream.Output {
        try await smtpStreamController.smtpStream(input, req: req)
    }
    
    let imapStreamController = IMAPStreamController()
    func imapStream(_ input: Operations.ImapStream.Input) async throws -> Operations.ImapStream.Output {
        try await imapStreamController.imapStream(input, req: req)
    }
}

@main struct Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)        
        let app = try await Application.make(env)

        do {
            app.logger.logLevel = .trace
            let handler = Handler()
            let transport = VaporTransport(routesBuilder: app.grouped(OpenAPIRequestInjectionMiddleware()))
            try handler.registerHandlers(on: transport)
            
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}


