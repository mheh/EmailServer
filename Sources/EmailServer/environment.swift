//
//  environment.swift
//  EmailServer
//
//  Created by Milo Hehmsoth on 9/8/25.
//

import Foundation

public enum Environment {
    case development
    case production
    case testing
    
    public static func detect() -> Environment {
        return .development
    }
}
