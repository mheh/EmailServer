import Vapor
import SwiftMail
import EmailServerAPI
import NIOIMAPCore

extension ReadingEmails.SwiftMailIMAP {
    actor Server {
        let server: SwiftMail.IMAPServer
        let config: ReadingEmails.SwiftMailIMAP.Server.Configuration
        
        init(config: ReadingEmails.SwiftMailIMAP.Server.Configuration) {
            self.server = .init(host: config.host, port: config.port, numberOfThreads: config.numberOfThreads)
            self.config = config
        }
        
        /// Concifugration for connecting to the server
        struct Configuration {
            /// The host address for the IMAP server
            let host: String
            /// The host port for the SMTP server
            let port: Int
            
            /// The number of threads to pass for the server to use
            let numberOfThreads: Int
            
            /// The user credentials to use for login
            let connectingUser: ReadingEmails.SwiftMailIMAP.User
            
            init(host: String, port: Int, numberOfThreads: Int = 1, connectingUser: ReadingEmails.SwiftMailIMAP.User) {
                self.host = host
                self.port = port
                self.numberOfThreads = numberOfThreads
                self.connectingUser = connectingUser
            }
        }
        
        func connect() async throws {
            try await self.server.connect()
        }
        
        func disconnect() async throws {
            try await self.server.disconnect()
        }
        
        func login() async throws {
            try await self.server.login(
                username: config.connectingUser.username,
                password: config.connectingUser.password)
        }
        
        func listMailBoxes() async throws -> [EmailServerAPI.Components.Schemas.IMAPMailboxInfo] {
            let mailBoxes = try await self.server.listMailboxes()
            var output: [EmailServerAPI.Components.Schemas.IMAPMailboxInfo] = []
            for mailBox in mailBoxes {
                let status = try await server.mailboxStatus(mailBox.name)
                output.append(.init(mailbox: mailBox, status: status))
            }
            return output
        }
    }
}

extension EmailServerAPI.Components.Schemas.IMAPMailboxInfo {
    init(mailbox: SwiftMail.Mailbox.Info, status: NIOIMAPCore.MailboxStatus) {
        self.init(
            name: mailbox.name,
            attributes: [],
            hierarchyDelimiter: {
                guard let hierarchyDelimiter = mailbox.hierarchyDelimiter else {
                    return nil
                }
                return "\(hierarchyDelimiter)"
            }(),
            isSelectable: mailbox.isSelectable,
            hasChildren: mailbox.hasChildren,
            hasNoChildren: mailbox.hasNoChildren,
            isMarked: mailbox.isMarked,
            isUnmarked: mailbox.isUnmarked)
    }
}
