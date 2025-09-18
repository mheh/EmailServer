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
    /// When performing grouping with connection IDs, this is a batch of emails
    typealias Batch = [UUID: [QueuedEmail]]
    
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
                
                /// Every `SMTP_EMAIL_BATCH_CLEAN` seconds check if our task is cancelled or not
                /// Create child tasks to send emails based on groups of connection IDs to send on.
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(Constants.Time.SMTP_EMAIL_BATCH_CLEAN))
                    // get our entire queue
                    let entireQueue = self.processEntireQueue()
                    if entireQueue.count > 0 {
                        Self.batchMetadata(entireQueue, logger: self.logger)
                    }
                    
                    // for batch of emails on a connection id
                    for batch in entireQueue {
                        // spin up a task to handle all of the emails
                        group.addTask {
                            guard let connection = await smtpConnectionRepository.find(id: batch.key) else {
                                await self.logger.error("Could not find a connection for batch \(batch.key)")
                                return
                            }
                            for email in batch.value {
                                await connection.send(email: email.email.swiftMailEmail)
                            }
                        }
                    }
                }
                
                try await group.waitForAll()
            }
        }
    }
    
    /// Split all queued emails into groups of connection ID
    private func processEntireQueue() -> Batch {
        // dequeue based on connection id
        let connectionIdGroups: Batch = self.queuedEmails
            .grouped(by: {$0.connectionId})
        self.queuedEmails.removeAll()
        return connectionIdGroups
    }
    
    static func batchMetadata(_ batch: Batch, logger: Logger) {
        var batchMetadata: Logger.Metadata = [:]
        for (id, queuedEmails) in batch {
            batchMetadata["\(id)"] = "count: \(queuedEmails.count)"
        }
        
        logger.debug("Processing batch", metadata: batchMetadata)
    }
}

extension SMTPEmailRepository {
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
