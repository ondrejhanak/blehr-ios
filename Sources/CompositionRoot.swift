//
//  CompositionRoot.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import CoreBluetooth
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
            centralManager: makeBluetoothService(),
            configuration: .default,
            now: Date.init
        )
    }

    private static func makeBluetoothService() -> BluetoothServiceType {
        #if DEBUG
        // Creating a CBCentralManager prompts for Bluetooth permission, which is unwanted in
        // the host app that only backs the test bundle.
        if AppEnvironment.isRunningTests {
            return InertBluetoothService()
        }
        #endif
        return CBCentralManager()
    }
}
