import Vapor
import QueuesRedisDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
    
    // Use redis for queues
//    try app.queues.use(.redis(url: "redis://127.0.0.1:6379"))
}
