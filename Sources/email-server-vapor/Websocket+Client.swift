//
//  Websocket+Client.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/15/25.
//

import Vapor
import WebSocketKit
import EmailServerAPI

actor SMTPClient {
    let session: WebSocketClient
    var connection: Connection?
    var logger: Logger
    
    init(
        req: Request,
        logger: Logger = .init(label: "SMTP Client"),
        logLevel: Logger.Level = .debug
    ) {
        self.session = .init(eventLoopGroupProvider: .shared(req.eventLoop))
        self.logger = logger
        self.logger.logLevel = logLevel
    }
    
    func connect(scheme: String = "ws", host: String, port: Int, smtpHost: String, smtpHostPort: Int) {
        let _ = self.session.connect(
            scheme: "ws",
            host: host,
            port: port,
            path: "smtp",
            query: "smtpHost=\(smtpHost)&smtpHostPort=\(smtpHostPort)",
            headers: .init([]),
            onUpgrade: handle(ws:))
    }
    
    private func handle(ws: WebSocket) {
        self.connection = .init(ws: ws, logger: self.logger)
    }
}

extension SMTPClient {
    actor Connection {
        typealias InboundStreamType = AsyncStream<WebsocketResponses>
        typealias OutboundStreamType = AsyncStream<WebsocketCommands>
        
        let ws: WebSocket
        let inbound: InboundStreamType
        private let inboundContinuation: InboundStreamType.Continuation
        
        let outbound: OutboundStreamType
        private let outboundContinuation: OutboundStreamType.Continuation
        
        private let task: Task<Void, any Error>
        
        let logger: Logger
        
        init(ws: WebSocket, logger: Logger) {
            self.ws = ws
            
            let (inboundStream, inboundStreamContinuation) = InboundStreamType.makeStream()
            self.inbound = inboundStream
            self.inboundContinuation = inboundStreamContinuation
            
            
            let (outboundStream, outboundStreamContinuation) = OutboundStreamType.makeStream()
            self.outbound = outboundStream
            self.outboundContinuation = outboundStreamContinuation
            
            let task = Task {
                try await Self.wsListeners(
                    ws: ws,
                    inboundContinuation: inboundStreamContinuation,
                    outbound: outboundStream,
                    outboundContinuation: outboundStreamContinuation)
            }
            self.task = task
            
            inboundStreamContinuation.onTermination = { _ in
                task.cancel()
            }
            
            self.logger = logger
        }
        
        static func wsListeners(
            ws: WebSocket,
            inboundContinuation: InboundStreamType.Continuation,
            outbound: OutboundStreamType,
            outboundContinuation: OutboundStreamType.Continuation
        ) async throws {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for try await command in outbound {
                        let data = try command.encode()
                        ws.send(data)
                    }
                }
                
                group.addTask {
                    ws.onBinary({ws, byteBuffer in
                        let response = try? WebsocketResponses.decode(data: .init(buffer: byteBuffer))
                        if let response {
                            inboundContinuation.yield(response)
                        }
                    })
                }
                
                group.addTask {
                    ws.onClose.whenComplete { _ in
                        inboundContinuation.finish()
                    }
                }
                
                try await group.waitForAll()
            }
        }
    }
}

