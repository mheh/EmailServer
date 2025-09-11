//
//  Server.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor
import OpenAPIVapor
import EmailServerAPI
import NIOCore
import NIOPosix
import Logging

struct Handler: APIProtocol {
    private let storage: StreamStorage = .init()
//    @Injected(\.request) var req: Request
    
    func smtpStream(_ input: EmailServerAPI.Operations.SmtpStream.Input) async throws -> EmailServerAPI.Operations.SmtpStream.Output {
        let eventStream = await self.storage.makeStream(input: input)
        
        let responseBody = Operations.SmtpStream.Output.Ok.Body.applicationJsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        
        return .ok(.init(body: responseBody))
    }
    
    func imapStream(_ input: Operations.ImapStream.Input) async throws -> Operations.ImapStream.Output {
        return .internalServerError
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


