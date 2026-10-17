//
//  BluetoothCentralType.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Foundation

/// What the sensor service asks of the radio, in terms a fake can satisfy.
protocol BluetoothCentralType: AnyObject {
    var delegate: BluetoothCentralDelegate? { get set }

    func startScanning()
    func stopScanning()
    func connect(id: UUID)
    func disconnect(id: UUID)
}

/// What the radio reports back: only events the state machine acts on, which leaves service
/// and characteristic discovery behind the boundary.
protocol BluetoothCentralDelegate: AnyObject {
    func centralDidChangeAvailability(to isAvailable: Bool)
    func centralDidDiscover(_ sensor: DiscoveredSensor)
    func centralDidFailToConnect(to id: UUID)
    func centralDidDisconnect(from id: UUID)
    func centralDidReceiveMeasurement(_ data: Data, from id: UUID, name: String?)
}
