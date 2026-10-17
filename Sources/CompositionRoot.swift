//
//  CompositionRoot.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Foundation

@MainActor
enum CompositionRoot {
    static func makeHeartRateViewModel() -> HeartRateViewModel {
        HeartRateViewModel(
            sensorService: makeSensorService(),
            settingsOpener: SystemSettingsOpener()
        )
    }

    private static func makeSensorService() -> SensorServiceType {
        SensorService(
            central: makeBluetoothCentral(),
            configuration: .default,
            now: Date.init
        )
    }

    private static func makeBluetoothCentral() -> BluetoothCentralType {
        #if DEBUG
        // Creating a real central prompts for Bluetooth permission, which is unwanted in
        // the host app that only backs the test bundle.
        if AppEnvironment.isRunningTests {
            return InertBluetoothCentral()
        }
        #endif
        return CoreBluetoothCentral()
    }
}
