//
//  AppEnvironmentTests.swift
//  tests
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Testing
@testable import BLE_HR

struct AppEnvironmentTests {
    /// Guards the check `CompositionRoot` relies on: were it to fail, the host app would
    /// create a real central and prompt for Bluetooth permission during test runs.
    @Test
    func detectsThatItIsRunningUnderTest() {
        #expect(AppEnvironment.isRunningTests)
    }
}
