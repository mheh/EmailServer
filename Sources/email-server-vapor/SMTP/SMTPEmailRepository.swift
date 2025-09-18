//
//  SMTPEmailRepository.swift
//  email-server
//
//  Created by Milo Hehmsoth on 9/17/25.
//

import Vapor
import SwiftMail
import EmailServerAPI

actor SMTPEmailRepository {
    /// Until getting around to using Vapor Queues, a stored array of emails to send
    private var queuedEmails: [QueuedEmail]
    
    private var processingTask: Task<Void, any Error>?
    
    var logger: Logger
    
    init(
        queuedEmails: [QueuedEmail] = [],
        logger: Logger = .init(label: "SMTP Email Repository"),
        logLevel: Logger.Level = .debug
    ) {
        self.queuedEmails = queuedEmails
        self.logger = logger
        self.logger.logLevel = logLevel
        self.processingTask = nil
    }
    
    public func add(emails: [QueuedEmail]) {
        self.queuedEmails.append(contentsOf: emails)
    }
    
    func startProcessTask(smtpConnectionRepository: SMTPConnectionRepository) {
        self.processingTask = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                
                /// Every thirty seconds check if our task is cancelled or not
                /// Create child tasks to send emails based on groups of connection IDs to send on.
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(Constants.Time.THIRTY_SECONDS))
                    
                    // get our entire queue
                    let entireQueue = self.processEntireQueue()
                    
                    // for batch of emails on a connection id
                    for batch in entireQueue {
                        // spin up a task to handle all of the emails
                        group.addTask {
                            guard let connection = await smtpConnectionRepository.find(id: batch.key) else {
                                await self.logger.error("Could not find a connection for batch \(batch.key)")
                                return
                            }
                            for email in batch.value {
                                do {
                                    try await connection.server.sendEmail(email.email.swiftMailEmail)
                                } catch {
                                    var loggerMetadata = await connection.connectionDetails.metadata()
                                    loggerMetadata["error"] = "\(error)"
                                    loggerMetadata["error_description"] = "\(error.localizedDescription)"
                                    await self.logger.error("Error encountered sending email: \(error)", metadata: loggerMetadata)
                                }
                            }
                        }
                    }
                }
                
                try await group.waitForAll()
            }
        }
    }
    
    /// Split all queued emails into groups of connection ID
    private func processEntireQueue() -> [UUID: [QueuedEmail]] {
        // dequeue based on connection id
        let connectionIdGroups = self.queuedEmails
            .grouped(by: {$0.connectionId})
        self.queuedEmails.removeAll()
        return connectionIdGroups
    }
    
    
    struct QueuedEmail: Codable {
        /// The active connection ID to use from storage
        let connectionId: UUID
        /// The stored email to be sent on the connection ID
        let email: QueuedEmailType
        
        
        
        /// A type of codable email that can be stored and decoded
        enum QueuedEmailType: Codable {
            case simpleSmtpEmail(EmailServerAPI.Components.Schemas.SimpleSMTPEmail)
            
            var swiftMailEmail: SwiftMail.Email {
                switch self {
                case .simpleSmtpEmail(let email): return .init(
                    sender: .init(name: email.sender.name, address: email.sender.address),
                    recipients: email.recepients.map { .init(name: $0.name, address: $0.address)},
                    ccRecipients: email.ccRecepients.map { .init(name: $0.name, address: $0.address)},
                    bccRecipients: email.bccRecepients.map { .init(name: $0.name, address: $0.address)},
                    subject: email.subject,
                    textBody: email.textBody,
                    htmlBody: email.htmlBody,
                    attachments: [])
                }
            }
        }
    }
}
