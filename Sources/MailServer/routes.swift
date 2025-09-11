//
//  routes.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor
import OpenAPIVapor
import EmailServerAPI

func routes(_ app: Application) throws {
    
    // Make middleware for OpenAPI to inject `Request` into the `APIProtocol` struct
    let requestInjectionMiddleware = OpenAPIRequestInjectionMiddleware()
    
    // Create a VaporTransport using app and use injection middleware
    let transport = VaporTransport(routesBuilder: app.grouped(requestInjectionMiddleware))
    
    let handler = OpenAPIHandler()
    
    try handler.registerHandlers(on: transport)
}

struct OpenAPIHandler: APIProtocol, @unchecked Sendable {
    @Injected(\.request) var req: Request
    
    let smtpStreamController = SMTPStreamController()
    func smtpStream(_ input: EmailServerAPI.Operations.SmtpStream.Input) async throws -> EmailServerAPI.Operations.SmtpStream.Output {
        try await smtpStreamController.smtpStream(input, req: req)
    }
}

