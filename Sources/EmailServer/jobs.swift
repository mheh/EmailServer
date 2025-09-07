import Vapor
import Queues

func jobs(_ app: Application) throws {
    app.queues.add(SendingEmails.SwiftMailSMTP.Server.SimpleEmailJob())
    
    try app.queues.startInProcessJobs(on: .default)
    try app.queues.startScheduledJobs()
}
