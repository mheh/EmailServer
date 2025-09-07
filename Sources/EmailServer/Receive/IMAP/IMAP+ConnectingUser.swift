import Vapor

extension ReadingEmails.SwiftMailIMAP {
    /// Vapor authenticatable user for per-request usage
    struct User: Authenticatable, Codable {
        let username: String
        let password: String
        
        struct UserAuthenticator: AsyncBasicAuthenticator {
            typealias User = ReadingEmails.SwiftMailIMAP.User
            
            func authenticate(basic: BasicAuthorization, for request: Request) {
                request.auth.login(ReadingEmails.SwiftMailIMAP.User(username: basic.username, password: basic.password))
            }
        }
    }
}
