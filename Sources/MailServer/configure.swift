//
//  configure.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
