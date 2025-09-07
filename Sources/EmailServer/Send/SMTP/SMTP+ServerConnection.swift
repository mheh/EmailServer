import Vapor
import EmailServerAPI
import SwiftMail

extension SendingEmails.SwiftMailSMTP {
    class Server {
        let server: SwiftMail.SMTPServer
        let config: SendingEmails.SwiftMailSMTP.Server.Configuration
        
        init(config: SendingEmails.SwiftMailSMTP.Server.Configuration) {
            self.config = config
            self.server = .init(host: config.host, port: config.port, numberOfThreads: config.numberOfThreads)
        }
        
        /// Configuration information for connecting to the server
        struct Configuration: Codable {
            /// The host address
            let host: String
            /// The host port
            let port: Int
            
            /// The number of threads to pass for the server to use
            let numberOfThreads: Int
            
            /// The user credentials to use for login
            let connectingUser: SendingEmails.SwiftMailSMTP.User
            
            init(host: String, port: Int, numberOfThreads: Int = 1, connectingUser: SendingEmails.SwiftMailSMTP.User) {
                self.host = host
                self.port = port
                self.numberOfThreads = numberOfThreads
                self.connectingUser = connectingUser
            }
        }
        
        
        func connect() async throws {
            try await self.server.connect()
        }
        
        func login() async throws {
            try await self.server.login(
                username: self.config.connectingUser.username,
                password: self.config.connectingUser.password)
        }
        
        func send(_ email: EmailServerAPI.Components.Schemas.SimpleSMTPEmail) async throws {
            try await self.server.sendEmail(.init(email))
        }
        
        func disconnect() async throws {
            try await self.server.disconnect()
        }
    }
}

extension SwiftMail.Email {
    init(_ email: EmailServerAPI.Components.Schemas.SimpleSMTPEmail) {
        self.init(
            sender: .init(email.sender),
            recipients: email.recepients.map { .init($0)},
            ccRecipients: email.ccRecepients.map { .init($0)},
            bccRecipients: email.bccRecepients.map { .init($0)},
            subject: email.subject,
            textBody: email.textBody,
            htmlBody: email.htmlBody,
            attachments: []
        )
    }
}

extension SwiftMail.EmailAddress {
    init(_ email: EmailServerAPI.Components.Schemas.EmailAddress) {
        self.init(name: email.name, address: email.address)
    }
}
