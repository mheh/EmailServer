//
//  Websocket+Route.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/14/25.
//

import Vapor
import EmailServerAPI

final class WebsocketUpgradeHandler: RouteCollection, Sendable {
    func boot(routes: any RoutesBuilder) throws {
        let smtp = routes.grouped("smtp", ":smtpHost", ":smtpHostPort")
        smtp.webSocket(onUpgrade: handleUpgrade(_:ws:))
    }
    
    func handleUpgrade(_ req: Request, ws: WebSocket) async {
        req.logger.debug("Upgrading a request...")
        // get host, port from parameters
        
        let host = req.parameters.get("smtpHost")!
        let portString = req.parameters.get("smtpHostPort")!
        
        guard let port = Int(portString) else {
            req.logger.error("No port provided")
            return
        }
        
        // add a new client to storage
        let client = await storage.new(
            request: req,
            websocket: ws,
            smtp: .init(id: UUID(), host: host, port: port)
        )
        
        do {
            try await client.smtp.connect()
        } catch {
            req.logger.report(error: error)
            await storage.disconnect(client: client)
            return // exit because we couldn't connect
        }
        
        // decode incoming binary objects
        ws.onBinary { ws, binary in
            req.logger.debug("Received binary")
            await self.decode(client: client, binary: binary, logger: req.logger)
        }
        
        // when closed remove the connection from local storage
        ws.onClose.whenComplete { result in
            Task {
                req.logger.debug("Closing websocket connection")
                // purge on close regardless of if succeeded or not
                do {
                    try await client.smtp.disconnect()
                } catch {
                    req.logger.report(error: error)
                }
                await storage.disconnect(client: client)
            }
        }
    }
}

extension WebsocketUpgradeHandler {
    func decode(client: SMTPConnectionRepository.ConnectedClient, binary: ByteBuffer, logger: Logger) async {
        do {
            let data = Data.init(buffer: binary)
            let decoded = try SMTPConnectionCommand.decode(data: data)
            
            switch decoded {
            case .connectionState(_):
                let state = await client.smtp.state()
                let data = try SMTPConnectionResponse.state(state).encode()
                client.websocket.send(data)
            case .login(let request):
                try await client.smtp.login(username: request.username, password: request.password)
            case .send(let request):
                try await client.smtp.send(.init(
                    sender: .init(name: request.sender.name, address: request.sender.address),
                    recipients: request.recipients.map { .init(name: $0.name, address: $0.address)},
                    ccRecipients: request.ccRecipients.map { .init(name: $0.name, address: $0.address)},
                    bccRecipients: request.bccRecipients.map { .init(name: $0.name, address: $0.address)},
                    subject: request.subject,
                    textBody: request.textBody,
                    htmlBody: request.htmlBody,
                    attachments: []))
            }
        } catch {
            logger.report(error: error)
        }
    }
}
