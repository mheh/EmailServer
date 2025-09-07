import Vapor
import EmailServerAPI

/// Email related reading
enum ReadingEmails {
    
    /// SwiftMail IMAP
    enum SwiftMailIMAP {}
}

struct ReceiveController {
    typealias MailboxesList = EmailServerAPI.Operations.ImapSwiftmailMailboxes
    func listMailboxes(input: MailboxesList.Input, req: Request) async throws -> MailboxesList.Output {
        print(req.headers)
        do {
            let user = try req.auth.require(ReadingEmails.SwiftMailIMAP.User.self)
            let configuration: ReadingEmails.SwiftMailIMAP.Server.Configuration = .init(
                host: input.path.imapHost,
                port: input.path.imapHostPort,
                numberOfThreads: 1,
                connectingUser: user)
            
            let imap = ReadingEmails.SwiftMailIMAP.Server(config: configuration)
            try await imap.connect()
            try await imap.login()
            let res = try await imap.listMailBoxes()
            try await imap.disconnect()
            return .ok(.init(body: .json(res)))
        } catch {
            req.logger.report(error: error)
            return .internalServerError
        }
    }
}
