import Vapor

extension SendingEmails.SwiftMailSMTP {
    /// Vapor authenticatable user for per-request usage
    struct User: Authenticatable, Codable {
        let username: String
        let password: String
        
        struct UserAuthenticator: AsyncBasicAuthenticator {
            typealias User = SendingEmails.SwiftMailSMTP.User
            
            func authenticate(basic: BasicAuthorization, for request: Request) {
                request.auth.login(SendingEmails.SwiftMailSMTP.User(username: basic.username, password: basic.password))
            }
        }
    }
}
