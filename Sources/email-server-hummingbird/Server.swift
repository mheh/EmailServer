//
//  Server.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/11/25.
//

import EmailServerAPI
import Hummingbird
import Logging

@main struct Entrypoint {
    static func main() async throws {
        var appLogger: Logger = .init(label: "App")
        appLogger.logLevel = .trace
        let router = Router()
        
        let app = Application(router: router, configuration: .init(), logger: appLogger)
        try await app.run()
    }
}
