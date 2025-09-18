//
//  Server.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import EmailServerAPI
import Vapor
import Logging

@main struct Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)        
        let app = try await Application.make(env)
        app.http.server.configuration.port = 8081

        do {
            // Inject req
            app.middleware.use(OpenAPIRequestInjectionMiddleware())
            
            // setup connection storage
            app.smtp = .init()
            await app.smtp.startCleanupTask()
            
            // setup email storage
            app.smtpEmails = .init()
            await app.smtpEmails.startProcessTask(smtpConnectionRepository: app.smtp)
            
            // register routes
            try routes(app)
            
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
