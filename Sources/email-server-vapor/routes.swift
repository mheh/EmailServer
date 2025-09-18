//
//  routes.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor
import OpenAPIVapor
import EmailServerAPI

public func routes(_ app: Application) throws {
    // Create a Vapor OpenAPI Transport using your application.
    let transport = VaporTransport(routesBuilder: app)

    // Create an instance of your handler type that conforms the generated protocol
    // defining your service API.
    let handler = Handler()

    // Call the generated function on your implementation to add its request
    // handlers to the app.
    try handler.registerHandlers(on: transport, middlewares: [])
}

struct Handler: APIProtocol, @unchecked Sendable {
    func smtpQueue(_ input: EmailServerAPI.Operations.SmtpQueue.Input) async throws -> EmailServerAPI.Operations.SmtpQueue.Output {
        guard case .json(let body) = input.body else { return .internalServerError }
        
        do {
            let connectionId = try await req.smtp.new(
                host: input.headers.smtpProvider.host,
                port: input.headers.smtpProvider.port,
                username: input.headers.smtpUsername,
                password: input.headers.smtpPassword)
            await req.smtpEmails.add(
                emails: body.map { .init(
                    connectionId: connectionId,
                    email: .simpleSmtpEmail($0)
                )}
            )
        } catch {
            req.logger.report(error: error)
            return .internalServerError
        }
        
        return .ok
    }
    
    @Injected(\.request) var req
}
