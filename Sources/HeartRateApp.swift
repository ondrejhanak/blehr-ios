//
//  HeartRateApp.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import CoreBluetooth
import SwiftUI

@main
struct HeartRateApp: App {
    var body: some Scene {
        WindowGroup {
            if isProduction {
                let centralManager = CBCentralManager()
                let sensorService = SensorService(centralManager: centralManager)
                let viewModel = HeartRateViewModel(sensorService: sensorService)
                HeartRateView(viewModel: viewModel)
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
