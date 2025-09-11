//
//  SMTPStream.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/10/25.
//

import Vapor
import SwiftMail
import EmailServerAPI

struct SMTPStreamController {
    typealias SMTPStreamOperation = EmailServerAPI.Operations.SmtpStream
    private let storage: StreamStorage = .init()
    
    func smtpStream(_ input: SMTPStreamOperation.Input, req: Request) async throws -> SMTPStreamOperation.Output {
        let eventStream = try await self.storage.makeStream(input: input, req: req)
        
        let responseBody: SMTPStreamOperation.Output.Ok.Body = .applicationJsonl(
            .init(eventStream.asEncodedJSONLines(), length: .unknown, iterationBehavior: .single)
        )
        return .ok(.init(body: responseBody))
    }
}

extension SMTPStreamController {
    actor StreamStorage: Sendable {
        typealias StreamOutput = AsyncStream<String>
//        typealias StreamInput = AsyncStream<Components.Schemas.SMTPServerStreamInput>
        
        /// The active streams for connected clients composed of `req.id` and the streaming task.
        private var streams: [String: Task<Void, any Error>] = [:]
        
        private var logger: Logger
        
        init(logger: Logger = .init(label: "SMTP Stream")) {
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
        
        
        func makeStream(input: Operations.SmtpStream.Input, req: Request) async throws -> StreamOutput {
            let id = req.id
            
            // setup the smtp server connection
            let host = input.query.smtpHost
            let port = input.query.smtpHostPort
            
            self.logger.debug("Creating a stream for \(id)")
            
            // make an outgoing stream
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
            
            // decode the incoming stream
            let inputMessages = switch input.body {
            case .applicationJsonl(let body): body.asDecodedJSONLines(of: Components.Schemas.SMTPServerStreamInput.self)
            }
            
            // form a task that handles the input from client and yields outgoing stream information
            let task = Task<Void, any Error> {
                // connect to the server successfully
                let server = SwiftMail.SMTPServer(host: host, port: port, numberOfThreads: 1)
                self.logger.debug("Attempting SMTP connect for \(id) at \(host):\(port)")
                do {
                    try await server.connect()
                } catch {
                    continuation.finish()
                }
                    
                // as long as http request is keep-alived, wait for inputs in the stream
                for try await message in inputMessages {
                    try Task.checkCancellation()
                    self.logger.debug("Received a message")
                    
                    switch message.input {
                        
                    case .SMTPLogin(let login):
                        do {
                            try await server.login(username: login.username, password: login.password)
                        } catch { continuation.yield(error.localizedDescription) }
                        
                    case .SMTPLogout(_):
                        do {
                            try await server.disconnect()
                            try await server.connect()
                            continuation.yield("Logged out")
                        } catch { continuation.yield(error.localizedDescription) }
                        
                    case .SimpleSMTPEmail(let email):
                        do {
                            try await server.sendEmail(.init(
                                sender: .init(name: email.sender.name, address: email.sender.address),
                                recipients: email.recepients.map { .init(name: $0.name, address: $0.address)},
                                subject: email.subject,
                                textBody: email.textBody
                            ))
                            continuation.yield("Sent!")
                        } catch { continuation.yield(error.localizedDescription) }
                            
                    }
                }
                
                // close the stream, no more keep alive
                try await server.disconnect()
                continuation.finish()
            }
            
            // assign the stream to storage
            self.streams[id] = task
            return stream
        }
    }
}
