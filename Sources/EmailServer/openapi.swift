import Vapor

import Dependencies
import EmailServerAPI

struct OpenAPIRoutesHandler: APIProtocol {
    let sendController = SendingEmails.Controller()
    
    func sendSwiftmailSimple(_ input: Operations.SendSwiftmailSimple.Input) async throws -> Operations.SendSwiftmailSimple.Output {
        try await sendController.swiftMailSimple(input, req: req)
    }
    func sendSendgridkitSimple(_ input: Operations.SendSendgridkitSimple.Input) async throws -> Operations.SendSendgridkitSimple.Output {
        try await sendController.sendGridKitSimple(input, req: req)
    }
    
    let receiveController = ReceiveController()
    func imapSwiftmailMailboxes(_ input: Operations.ImapSwiftmailMailboxes.Input) async throws -> Operations.ImapSwiftmailMailboxes.Output {
        try await receiveController.listMailboxes(input: input, req: req)
    }
    
    @Dependency(\.request) var req: Request
}
