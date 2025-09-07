import Vapor
import OpenAPIVapor

func routes(_ app: Application) throws {
    // Make middleware for OpenAPI to inject `Request` into the `APIProtocol` struct
    let requestInjectionMiddleware = OpenAPIRequestInjectionMiddleware()
    // Create a VaporTransport using app and use injection middleware
    let transport = VaporTransport(routesBuilder: app.grouped(
        requestInjectionMiddleware,
        SendingEmails.SwiftMailSMTP.User.UserAuthenticator(),
        ReadingEmails.SwiftMailIMAP.User.UserAuthenticator()
    ))
    
    // Make an instance of the OpenAPI routes
    let handler = OpenAPIRoutesHandler()
    
    // Register the OpenAPI routes with the transport
    // use Middleware to require Bearer auth on every request
    try handler.registerHandlers(
        on: transport,
        middlewares: []
    )
}
