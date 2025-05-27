//
//  GlobalFunctions.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 29.04.2025.
//

import Foundation
import OSLog

func createLogger(subsystem:String, category:String) -> Logger {
    #if DEBUG
    return Logger(subsystem: subsystem, category: category)
    #else
    return Logger(.disabled)
    #endif
}
