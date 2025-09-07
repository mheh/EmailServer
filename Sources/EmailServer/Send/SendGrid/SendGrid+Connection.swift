import Vapor
import EmailServerAPI
import SendGridKit

extension SendingEmails.SendGrid {
    class Server {
        let client: SendGridKit.SendGridClient
        let config: SendingEmails.SendGrid.Server.Configuration

        
        init(config: SendingEmails.SendGrid.Server.Configuration, httpClient: AsyncHTTPClient.HTTPClient) {
            self.client = .init(httpClient: httpClient, apiKey: config.apiKey, forEU: config.forEU)
            self.config = config
        }
        
        /// Configuration information for connecting to Sendgrid
        struct Configuration: Codable {
            /// The `APIKey` used to connect a `SendGridClient` with
            let apiKey: String
            let forEU: Bool
            
            init(apiKey: String, forEU: Bool) {
                self.apiKey = apiKey
                self.forEU = forEU
            }
        }
        
        func send(_ email: EmailServerAPI.Components.Schemas.SimpleSendGridKitEmail) async throws {
            let emailToSend: SendGridKit.SendGridEmail<String> = .init(email)
            try await self.client.send(email: emailToSend)
        }
    }
}

extension SendGridKit.SendGridEmail {
    init(_ email: EmailServerAPI.Components.Schemas.SimpleSendGridKitEmail) {
        
        let to: [SendGridKit.EmailAddress] = {
            switch email.replyTo {
            case .EmailAddress(let email): return [.init(email)]
            case .SimpleSendGridKitEmailReplyToList(let emails): return emails.map { .init($0)}
            }
        }()
        
        // to + subject
        
        let emailContent = SendGridKit.EmailContent.init(type: "text/plain", value: email.textBody)
        
        let mailSettings = MailSettings(
                  bypassListManagement: nil,
                  bypassSpamManagement: true,
                  bypassBounceManagement: true,
                  footer: false,
                  sandboxMode: true
              )
        
        self.init(
            personalizations: [SendGridKit.Personalization(
                to: to ,
                subject: email.subject,
            dynamicTemplateData: nil)],
            from: .init(email.from),
            replyTo: nil,
            replyToList: nil,
            subject: email.subject,
            content: [emailContent],
            attachments: nil,
            templateID: nil,
            headers: nil,
            categories: nil,
            customArgs: nil,
            sendAt: nil,
            batchID: nil,
            asm: nil,
            ipPoolName: nil,
            mailSettings: mailSettings,
            trackingSettings: nil)
    }
}

extension SendGridKit.EmailAddress {
    
    init(_ email: EmailServerAPI.Components.Schemas.EmailAddress) {
        self.init(email: email.address, name: email.name)
    }
}
