//
//  routes.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor
import EmailServerAPI

public func routes(_ app: Application) throws {
    
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
