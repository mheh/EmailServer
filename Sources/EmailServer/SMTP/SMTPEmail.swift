////
////  SMTPEmail.swift
////  EmailServer
////
////  Created by Milo Hehmsoth on 9/8/25.
////
//
//#if canImport(FoundationEssentials)
//import FoundationEssentials
//#else
//import Foundation
//#endif
//
//import SwiftMail
//
//extension SMTPSessions.Connection {
//    public struct EmailAddress: Codable, Sendable {
//        public let name: String?
//        public let address: String
//    }
//    
//    public struct Email: Codable, Sendable {
//        public var sender: SMTPSessions.Connection.EmailAddress
//        public var recipients: [SMTPSessions.Connection.EmailAddress]
//        public var ccRecipients: [SMTPSessions.Connection.EmailAddress]
//        public var bccRecipients: [SMTPSessions.Connection.EmailAddress]
//        public var subject: String
//        public var textBody: String
//        public var htmlBody: String
//        
//        public init(
//            sender: SMTPSessions.Connection.EmailAddress,
//            recipients: [SMTPSessions.Connection.EmailAddress],
//            ccRecipients: [SMTPSessions.Connection.EmailAddress],
//            bccRecipients: [SMTPSessions.Connection.EmailAddress],
//            subject: String,
//            textBody: String,
//            htmlBody: String
//        ) {
//            self.sender = sender
//            self.recipients = recipients
//            self.ccRecipients = ccRecipients
//            self.bccRecipients = bccRecipients
//            self.subject = subject
//            self.textBody = textBody
//            self.htmlBody = htmlBody
//        }
//    }
//}
//
//extension SwiftMail.Email {
//    init(_ email: SMTPSessions.Connection.Email) {
//        self.init(
//            sender: .init(email.sender),
//            recipients: email.recipients.map { .init($0)},
//            ccRecipients: email.ccRecipients.map { .init($0)},
//            bccRecipients: email.bccRecipients.map { .init($0)},
//            subject: email.subject,
//            textBody: email.textBody,
//            htmlBody: email.htmlBody,
//            attachments: nil
//        )
//    }
//}
//
//extension SwiftMail.EmailAddress {
//    init(_ address: SMTPSessions.Connection.EmailAddress) {
//        self.init(name: address.name, address: address.address)
//    }
//}
