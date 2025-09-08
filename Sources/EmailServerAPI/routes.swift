//
//  SMTPRoutes.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import MCP
import SwiftMail

func routes(server: Server) async throws {
    await server.withMethodHandler(SMTPSend.self, handler: { params in
        let from = params.from
        return .init()
    })
}

struct SMTPSend: Method {
    static let name: String = "sendSmtp"
    typealias Parameters = Input
    
    struct Input: Codable, Hashable, Sendable {
        let from: String
//        let email: SwiftMail.Email
    }
}
