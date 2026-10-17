//
//  InertBluetoothCentral.swift
//  blehr
//
//  Created by Ondrej Hanak on 17.10.2026.
//

import Foundation

#if DEBUG
/// Central that answers nothing, letting the real `SensorService` run without a radio.
final class InertBluetoothCentral: BluetoothCentralType {
    weak var delegate: BluetoothCentralDelegate?

    func startScanning() {}
    func stopScanning() {}
    func connect(id: UUID) {}
    func disconnect(id: UUID) {}
}
#endif
