//
//  EmailServer.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import EmailServerAPI
import MCP

public func configure() throws -> ServerConfiguration {
    let name = ProcessInfo.processInfo.environment["SERVER_NAME"] ?? "MailServer"
    let version = ProcessInfo.processInfo.environment["SERVER_VERSION"] ?? "0.0.1"
    
    let configuration: Server.Configuration = ProcessInfo.processInfo.environment["SERVER_CONFIGURATION"]
        .map { serverConfiguration in
            switch serverConfiguration.capitalized {
            case "DEFAULT": return .default
            case "STRICT": return .strict
            default: return .default
            }
        } ?? .default

    return .init(
        name: name, version: version,
        instructions: nil,
        capabilities: .init(),
        configuration: configuration)
}

public struct ServerConfiguration: Sendable {
    let name: String
    let version: String
    let instructions: String?
    let capabilities: Server.Capabilities
    let configuration: Server.Configuration
}
