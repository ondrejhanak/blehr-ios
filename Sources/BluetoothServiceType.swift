//
//  BluetoothServiceType.swift
//  blehr
//
//  Created by Ondrej Hanak on 15.11.2025.
//

import CoreBluetooth

protocol BluetoothServiceType: AnyObject {
    var delegate: (any CBCentralManagerDelegate)? { get set }

    func stopScan()
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
    func connect(_ peripheral: CBPeripheral, options: [String : Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheral)
}

extension CBCentralManager: BluetoothServiceType {}
