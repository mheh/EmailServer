import Foundation
import ServiceLifecycle
import Logging
import MCP

@main
struct Application {
    static func main() async throws {
        let environment = Environment.detect()
        try LoggingSystem.bootstrap(environment: environment)
        let logger = Logger(label: "MCPService")
        
        let ioTransport = StdioTransport()
        let service = MCPService(transport: ioTransport, configuration: try configure(), logger: logger)
        
        let serviceGroup = ServiceGroup(
            services: [service],
            gracefulShutdownSignals: [.sigterm],
            logger: logger
        )
        
        try await serviceGroup.run()
    }
}

fileprivate struct MCPService: Service {
    let server: Server
    let transport: Transport
    let logger: Logger
    
    init(transport: Transport, configuration: ServerConfiguration, isRunning: Bool = false, logger: Logger) {
        self.server = .init(config: configuration)
        self.transport = transport
        self.logger = logger
    }
    
    func run() async throws {
        print("Server started")
        // Start the server
        try await server.start(transport: transport)
        
        // Keep running until external cancellation
        //            try await Task.sleep(for: .days(365 * 100))  // Effectively forever
        try await Task.sleep(for: .init(.hours(24 * 365 * 100)))
    }
    
    func shutdown() async throws {
        print("Shutting down server")
        // Gracefully shutdown the server
        await server.stop()
    }
}

extension Server {
    init(config: ServerConfiguration) {
        self.init(name: config.name, version: config.version, instructions: config.instructions, capabilities: config.capabilities, configuration: config.configuration)
    }
}
