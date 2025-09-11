//
//  Server.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import EmailServerAPI
import OpenAPIRuntime
import OpenAPIHummingbird
import Hummingbird
import Foundation
import Logging

struct Handler: APIProtocol {
    private let storage: StreamStorage = .init()
    typealias SMTPStream = Operations.SmtpStream
    
    func smtpStream(_ input: Operations.SmtpStream.Input) async throws -> Operations.SmtpStream.Output {
        let eventStream = await self.storage.makeStream(input: input)
        
        let responseBody = Operations.SmtpStream.Output.Ok.Body.applicationJsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        
        return .ok(.init(body: responseBody))
    }
    
    func imapStream(_ input: Operations.ImapStream.Input) async throws -> Operations.ImapStream.Output {
        return .internalServerError
    }
}

@main struct BidirectionalEventStreamsServer {
    static func main() async throws {
        let router = Router()
        let handler = Handler()
        try handler.registerHandlers(on: router, serverURL: URL(string: "/")!)
        var appLogger: Logger = .init(label: "App")
        appLogger.logLevel = .trace
        let app = Application(router: router, configuration: .init(), logger: appLogger)
        try await app.run()
    }
}
