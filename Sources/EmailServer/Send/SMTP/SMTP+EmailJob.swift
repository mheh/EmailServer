import Vapor
import Queues
import EmailServerAPI

extension SendingEmails.SwiftMailSMTP.Server {
    /// The Job stored in redis to be completed
    struct SimpleEmailJobRequest: Codable {
        /// Information for connecting to the server or at a later date, local lookup for an active connection.
        let config: SendingEmails.SwiftMailSMTP.Server.Configuration
        /// The email being sent
        let email: EmailServerAPI.Components.Schemas.SimpleSMTPEmail
  
    }
    
    struct SimpleEmailJob: AsyncJob {
        typealias Payload = SendingEmails.SwiftMailSMTP.Server.SimpleEmailJobRequest
        
        func dequeue(_ context: QueueContext, _ payload: SendingEmails.SwiftMailSMTP.Server.SimpleEmailJobRequest) async throws {
            context.logger.info("Starting email job from \(payload.config.connectingUser.username)")
            
            let smtpServer = SendingEmails.SwiftMailSMTP.Server(config: payload.config)
            try await smtpServer.connect()
            context.logger.info("SMTP connection successful")

            try await smtpServer.login()
            context.logger.info("SMTP login successful")

            try await smtpServer.send(payload.email)
            context.logger.info("SMTP email sent successfully")

            try await smtpServer.disconnect()
            context.logger.info("SMTP email sent successfully")
        }
        
        func _error(_ context: QueueContext, id: String, _ error: any Error, payload: [UInt8]) async throws {
            context.logger.error("Encountered an error for id: \(id)")
            context.logger.report(error: error)
        }
    }
}
