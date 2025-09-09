//
//  SMTPEmail.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation

public struct EmailAddress: Codable {
    public let name: String?
    public let email: String
}

public struct Email: Codable {
    public var sender: EmailAddress
    public var recepients: [EmailAddress]
    public var ccRecepients: [EmailAddress]
    public var bccRecepients: [EmailAddress]
    public var subject: String
    public var textBody: String
    public var htmlBody: String
    public var attachmnents: [Attachment]
}

public struct Attachment: Codable {
    public var mimeType: String
    public var data: Data
}

