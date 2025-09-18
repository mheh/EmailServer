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
            app.logger.logLevel = .trace
            
            app.smtp = .init()
            await app.smtp.startCleanupTask()
            
            app.smtpEmails = .init()
            await app.smtpEmails.startProcessTask(smtpConnectionRepository: app.smtp)
            
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
