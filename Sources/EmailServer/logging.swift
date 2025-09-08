//
//  logging.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation
import Logging
import ConsoleKit

extension LoggingSystem {
    public static func bootstrap(environment: Environment) throws {
        let console = Terminal()
        
        let level: Logger.Level? = ProcessInfo.processInfo.environment["LOG_LEVEL"]
            .flatMap { processLogLevel in
                guard let level = Logger.Level(
                    rawValue: processLogLevel
                        .lowercased()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                ) else {
                    return nil
                }
                return level
            }
        
        return LoggingSystem.bootstrap(
            console: console,
            level: level ?? .debug)
    }
}
