//
//  routes.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
