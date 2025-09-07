import Vapor
import EmailServerAPI

/// Email sending related
enum SendingEmails {
    /// Sendgrid sending
    enum SendGrid {}
    
    /// Amazon SES sending
    enum SES {}
    
    /// SwiftMail SMTP sending
    enum SwiftMailSMTP {}
}

extension SendingEmails {
    /// OpenAPI routes for sending
    struct Controller {
        typealias SwiftMailSimple = EmailServerAPI.Operations.SendSwiftmailSimple
        
        func swiftMailSimple(_ input: SwiftMailSimple.Input, req: Request) async throws -> SwiftMailSimple.Output {
            let user = try req.auth.require(SendingEmails.SwiftMailSMTP.User.self)
            guard case .json(let body) = input.body else { throw Abort(.badRequest) }
            
            let job = SendingEmails.SwiftMailSMTP.Server.SimpleEmailJobRequest.init(
                config: .init(
                    host: input.path.smtpHost,
                    port: input.path.smtpHostPort,
                    numberOfThreads: 1,
                    connectingUser: user),
                email: body)
            
            do {
                let server = SendingEmails.SwiftMailSMTP.Server.init(config: job.config)
                try await server.connect()
                try await server.login()
                try await server.send(job.email)
                try await server.disconnect()
            } catch {
                req.logger.report(error: error)
                return .internalServerError
            }
            
            return .ok
        }
        
        typealias SendGridKitSImple = EmailServerAPI.Operations.SendSendgridkitSimple
        func sendGridKitSimple(_ input: SendGridKitSImple.Input, req: Request) async throws -> SendGridKitSImple.Output {
            // really we don't need auth for this one but it'd be good to have it
//            let user = try req.auth.require(
            guard case .json(let body) = input.body else { throw Abort(.badRequest) }
            
            do {
                let config: SendingEmails.SendGrid.Server.Configuration = .init(
                    apiKey: input.path.apiKey,
                    forEU: false)
                let server = SendingEmails.SendGrid.Server(config: config, httpClient: HTTPClient.shared)
                try await server.send(body)
            } catch {
                req.logger.report(error: error)
                return .internalServerError
            }
            
            return .ok
        }
    }
}
