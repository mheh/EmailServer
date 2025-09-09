//
//  EmailServer+Command.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import ArgumentParser
import SwiftMCP

@main
final class EmailServerCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start an HTTP server with SSE support",
        usage: "",
        discussion: "",
        version: "1.0",
        shouldDisplay: true,
        subcommands: [],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: [])
    
    @Option(name: .shortAndLong, help: "The address to serve on") var host: String
    
    @Option(name: .long, help: "The port to listen on") var port: Int
    
    func run() async throws {
        let server = EmailServer()
        let transport = HTTPSSETransport(server: server, host: self.host, port: self.port)
        
        
        transport.serveOpenAPI = true
        print("Running")
        try await transport.run()
    }
}
