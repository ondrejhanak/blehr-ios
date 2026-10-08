//
//  AppEnvironment.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Foundation

enum AppEnvironment {
    /// True when the process was launched only to host a test bundle.
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }
}
