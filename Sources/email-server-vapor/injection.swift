//
//  injection.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor
import OpenAPIRuntime
import OpenAPIVapor

// taken from: https://github.com/swift-server/swift-openapi-vapor/issues/24

struct Injection {
    @TaskLocal static var current: Injection?

    let request: Request
}

@propertyWrapper
struct Injected<T> {
    let keyPath: KeyPath<Injection, T>

    init(_ keyPath: KeyPath<Injection, T>) {
        self.keyPath = keyPath
    }

    var wrappedValue: T {
        get {
            guard let current = Injection.current else {
                fatalError("Injection not registered in this context")
            }
            return current[keyPath: keyPath]
        }
    }
}

struct OpenAPIRequestInjectionMiddleware: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo responder: any AsyncResponder
    ) async throws -> Response {
        try await Injection.$current.withValue(.init(request: request)) {
            try await responder.respond(to: request)
        }
    }
}
