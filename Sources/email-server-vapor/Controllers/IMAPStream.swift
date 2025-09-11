//
//  IMAPStream.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor
import SwiftMail
import EmailServerAPI

struct IMAPStreamController {
    typealias IMAPStreamOperation = EmailServerAPI.Operations.ImapStream
    private let storage: StreamStorage = .init()
    
    func imapStream(_ input: IMAPStreamOperation.Input, req: Request) async throws -> IMAPStreamOperation.Output {
        let eventStream = try await self.storage.makeStream(input: input, req: req)
        
        let responseBody: IMAPStreamOperation.Output.Ok.Body = .applicationJsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        return .ok(.init(body: responseBody))
    }
}

extension IMAPStreamController {
    actor StreamStorage: Sendable {
        typealias StreamOutput = AsyncStream<String>
        
        
        /// The active streams for connected clients composed of `req.id` and the streaming task.
        private var streams: [String: Task<Void, any Error>] = [:]
        
        private var logger: Logger
        
        init(logger: Logger = .init(label: "IMAP")) {
            self.logger = logger
            self.logger.logLevel = .trace
        }
        
        private func finishedStream(id: String) {
            guard self.streams[id] != nil else { return }
            self.streams.removeValue(forKey: id)
        }
        
        private func cancelStream(id: String) {
            guard let task = self.streams[id] else { return }
            self.streams.removeValue(forKey: id)
            task.cancel()
            self.logger.debug("Cancelled stream \(id)")
        }
        
        func makeStream(input: Operations.ImapStream.Input, req: Request) async throws -> StreamOutput {
            let id = req.id
            
            // setup the imap connection
            let host = input.query.imapHost
            let port = input.query.imapHostPort
            let meta: Logger.Metadata = [ "id": "\(id)", "host":"\(host)", "port":"\(port)" ]
            
            self.logger.info("Creating stream", metadata: meta)
            
            let (stream, continuation) = StreamOutput.makeStream()
            continuation.onTermination = { termination in
                Task { [weak self] in
                    switch termination {
                    case .cancelled: await self?.cancelStream(id: id)
                    case .finished: await self?.finishedStream(id: id)
                    @unknown default: await self?.finishedStream(id: id)
                    }
                }
            }
            
            let task = Task<Void, any Error> {
                // connect to the server successfully
                let server = SwiftMail.IMAPServer(host: host, port: port, numberOfThreads: 1)
                self.logger.debug("Connecting...", metadata: meta)
                do { try await server.connect() }
                catch { continuation.finish() }
                self.logger.debug("Connected", metadata: meta)
                
                // wait for inputs to stream
                
                // close the stream
                self.logger.debug("Disconnecting...", metadata: meta)
                do {
                    try await server.disconnect()
                    self.logger.debug("Disconnected", metadata: meta)
                }
                catch { self.logger.report(error: error, metadata: meta) }
            }
            
            // assign the stream to storage
            self.streams[id] = task
            return stream
        }
    }
}
