@testable import EmailServer
import VaporTesting
import Testing
import EmailServerAPI
import OpenAPIRuntime
import HTTPTypes


@Suite("App Tests")
struct EmailServerTests {
    @Test("IMAP Reading successfully")
    func helloWorld() async throws {
        let app = try! await Application.make(.testing)
        do {
            try await configure(app)
            
            let client = EmailServerAPI.Client.init(app: app, username: "user", password: "password")
        
            let res = try await client.imapSwiftmailMailboxes(.init(
                path: .init(imapHost: "TESTYOURHOST", imapHostPort: 993)))
            switch res {
            case .internalServerError:
                print("Error")
            case .ok(let mailboxes):
                print(mailboxes)
            case .undocumented(let statusCode, /*somePayload*/ _):
                print("Status: \(statusCode)")
                
            }
            
        } catch {
            print(error)
        }
        
        
        try await app.asyncShutdown()
    }
    
    @Test("SendGrid Send successfully")
    func sendGridSend() async throws {
        let app = try! await Application.make(.testing)
        try await configure(app)
        
        do {
            let client = EmailServerAPI.Client.init(app: app, username: "user", password: "password")
            let res = try await client.sendSendgridkitSimple(.init(
                path: .init(apiKey: ""),
                body: .json(.init(
                    from: .init(address: "test@yourhost.here"),
                    replyTo: .EmailAddress(.init(name: "", address: "")),
                    subject: "Test Subject",
                    textBody: "Success!"))))
            switch res {
            case .ok:
                print("OK")
            case .internalServerError:
                print("Internal error")
            case .undocumented(let statusCode, _):
                print("Unexpected: \(statusCode)")
            }
        } catch {
            print(error)
        }
        
        
        try await app.asyncShutdown()
    }
}


struct TestClient_Transport: ClientTransport {
    var app: Application
    
    func send(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        baseURL: URL, operationID: String
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        // send to the custom Application.test func
        return try await app.test(request: request, body: body)
    }
}


extension URL {
    /// This isn't even used by the client, but it's required to be there.
    fileprivate static func localhost() -> URL {
        return URL(string: "http://localhost:8080")!
    }
}

extension EmailServerAPI.Client {
    /// Initialize a testing client with custom transport and middleware.
    init(app: Application, username: String, password: String) {
        // url is unused fyi
        let base64String = "\(username):\(password)".base64String()
        self.init(
            serverURL: URL.localhost(),
            transport: TestClient_Transport(app: app),
            middlewares: [BasicAuthMiddleware(base64String: base64String)]
        )
    }
}

extension Application {
    /// Test the `OpenAPI` request and return the response
    func test(
        request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        
        // for some reason the request.path from openapi is optional
        guard let pathExists = request.path else {
            throw Abort(.internalServerError, reason: "Request path is nil")
        }
        
        // the path
        let path = pathExists
        
        // copy headers from openapi request to vapor request
        var headers = HTTPHeaders()
        for header in request.headerFields {
            headers.add(name: header.name.rawName, value: header.value)
        }
        
        // if there's a body, collect it
        var bodyByteBuffer: ByteBuffer?
        if let body {
            switch body.length {
            case .known(let length):
                bodyByteBuffer = try await body.collect(upTo: Int(length), using: .init())
            default: break
            }
        }
        
        // form a var for response
        var testingResponse: TestingHTTPResponse?
        
        try await self.test(
            .init(openapi: request.method),
            path,
            headers: headers,
            body: bodyByteBuffer,
            beforeRequest: { _ in
                // we shouldn't have to touch this for openapi requests
            },
            afterResponse: { res in
                // we steal the response here and convert it to openapi below
                testingResponse = res
            }
        )
        
        guard let testingResponse else {
            throw Abort(.internalServerError, reason: "Testing response is nil")
        }
        let response = HTTPTypes.HTTPResponse(from: testingResponse)
        let body = OpenAPIRuntime.HTTPBody(from: testingResponse)
        return (response, body)
    }
}


extension HTTPMethod {
    /// Init a `Vapor` HTTPMethod from an `OpenAPI/HTTPTypes` HTTPRequest.Method
    init(openapi: HTTPTypes.HTTPRequest.Method) {
        self.init(rawValue: openapi.rawValue)
    }
}

extension HTTPTypes.HTTPResponse {
    /// Init an `OpenAPI/HTTPTypes` HTTPResponse from a vapor `TestingHTTPResponse`
    init(from response: TestingHTTPResponse) {
        var headers = HTTPFields()
        for (key, value) in response.headers {
            headers.append(.init(name: .init(key)!, value: value))
        }
        self.init(
            status: .init(code: Int(response.status.code)),
            headerFields: headers
        )
    }
}

extension OpenAPIRuntime.HTTPBody {
    /// Init an `OpenAPI/HTTPTypes` HTTPBody from a vapor `TestingHTTPResponse`
    convenience init?(from response: TestingHTTPResponse) {
        guard response.body.string != "" else {
            return nil
        }
        self.init(stringLiteral: response.body.string)
    }
}
