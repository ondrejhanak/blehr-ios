//
//  CoreBluetoothCentral.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import CoreBluetooth

/// Translates between CoreBluetooth and `BluetoothCentralType`. Holds no policy of its own, so
/// the behaviour worth testing all sits above it in `SensorService`.
final class CoreBluetoothCentral: NSObject, BluetoothCentralType {
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let manager: CBCentralManager
    private var connectedPeripheral: CBPeripheral?

    weak var delegate: BluetoothCentralDelegate?

    // MARK: - Lifecycle

    override init() {
        // An explicit main queue, rather than relying on what a nil queue implies.
        manager = CBCentralManager(delegate: nil, queue: .main)
        super.init()
        manager.delegate = self
    }

    // MARK: - Methods

    func startScanning() {
        manager.scanForPeripherals(
            withServices: [heartRateServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        manager.stopScan()
    }

    func connect(id: UUID) {
        guard let peripheral = manager.retrievePeripherals(withIdentifiers: [id]).first else {
            delegate?.centralDidFailToConnect(to: id)
            return
        }
        peripheral.delegate = self
        connectedPeripheral = peripheral
        manager.connect(peripheral, options: nil)
    }

    func disconnect(id: UUID) {
        guard let connectedPeripheral, connectedPeripheral.identifier == id else { return }
        manager.cancelPeripheralConnection(connectedPeripheral)
    }

    // MARK: - Private

    private func releasePeripheral() {
        // Clearing the delegate stops late notifications from the old peripheral.
        connectedPeripheral?.delegate = nil
        connectedPeripheral = nil
    }
}

extension CoreBluetoothCentral: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let isAvailable = central.state == .poweredOn
        if !isAvailable {
            releasePeripheral()
        }
        delegate?.centralDidChangeAvailability(to: isAvailable)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        guard let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool, isConnectable else {
            return
        }
        delegate?.centralDidDiscover(
            DiscoveredSensor(id: peripheral.identifier, name: peripheral.name, rssi: RSSI.intValue)
        )
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        releasePeripheral()
        delegate?.centralDidFailToConnect(to: peripheral.identifier)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        releasePeripheral()
        delegate?.centralDidDisconnect(from: peripheral.identifier)
    }
}

extension CoreBluetoothCentral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == heartRateServiceUUID }) else { return }
        peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == heartRateMeasurementUUID }) else {
            return
        }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        delegate?.centralDidReceiveMeasurement(data, from: peripheral.identifier, name: peripheral.name)
    }
}
