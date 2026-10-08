//
//  BluetoothCentralType.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Foundation

/// What the sensor service asks of the radio, free of CoreBluetooth types so it can be faked.
protocol BluetoothCentralType: AnyObject {
    var delegate: BluetoothCentralDelegate? { get set }

    func startScanning()
    func stopScanning()
    func connect(id: UUID)
    func disconnect(id: UUID)
}

/// What the radio reports back. Service and characteristic discovery stay behind the boundary,
/// so only the events the state machine acts on appear here.
protocol BluetoothCentralDelegate: AnyObject {
    func centralDidChangeAvailability(to isAvailable: Bool)
    func centralDidDiscover(_ sensor: DiscoveredSensor)
    func centralDidFailToConnect(to id: UUID)
    func centralDidDisconnect(from id: UUID)
    func centralDidReceiveMeasurement(_ data: Data, from id: UUID, name: String?)
}
