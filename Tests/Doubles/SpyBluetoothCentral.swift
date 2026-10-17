//
//  SpyBluetoothCentral.swift
//  tests
//
//  Created by Ondrej Hanak on 17.10.2026.
//

import Foundation
@testable import BLE_HR

final class SpyBluetoothCentral: BluetoothCentralType {
    weak var delegate: BluetoothCentralDelegate?

    private(set) var isScanning = false
    private(set) var startScanningCallCount = 0
    private(set) var connectedIDs: [UUID] = []
    private(set) var disconnectedIDs: [UUID] = []

    func startScanning() {
        isScanning = true
        startScanningCallCount += 1
    }

    func stopScanning() {
        isScanning = false
    }

    func connect(id: UUID) {
        connectedIDs.append(id)
    }

    func disconnect(id: UUID) {
        disconnectedIDs.append(id)
    }
}
