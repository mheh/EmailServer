//
//  Websocket+SMTPRepository.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/14/25.
//

import Vapor
import EmailServerAPI

actor SMTPConnectionRepository {
    private var storage: [UUID: ConnectedClient]
    
    var logger: Logger
    
    init(storage: [UUID : ConnectedClient] = [:], logger: Logger = .init(label: "SMTP Repository")) {
        self.storage = storage
        self.logger = logger
    }
    
    public func new(request: Request, websocket: WebSocket, smtp: SMTPConnection) async -> ConnectedClient {
        let id = smtp.id
        let newConnectedClient = await ConnectedClient(request: request, websocket: websocket, smtp: smtp)
        self.storage[id] = newConnectedClient
        return newConnectedClient
    }
    
    public func disconnect(client: ConnectedClient) async {
        guard let found = self.storage.removeValue(forKey: client.id) else {
            self.logger.debug("Disconnection failed ID not found \(client.id.uuidString)")
            return
        }
        do {
            try await found.smtp.disconnect()
        } catch {
            self.logger.report(error: error)
        }
    }
}

extension SMTPConnectionRepository {
    struct ConnectedClient: Identifiable, Hashable {
        let id: UUID
        let request: Request
        let websocket: WebSocket
        let smtp: SMTPConnection
        
        init(request: Request, websocket: WebSocket, smtp: SMTPConnection) async {
            self.request = request
            self.websocket = websocket
            self.smtp = smtp
            self.id = smtp.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        static func == (lhs: SMTPConnectionRepository.ConnectedClient, rhs: SMTPConnectionRepository.ConnectedClient) -> Bool {
            return lhs.id == rhs.id
        }
    }
}
