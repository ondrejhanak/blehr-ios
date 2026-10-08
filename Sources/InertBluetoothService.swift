//
//  InertBluetoothService.swift
//  blehr
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import CoreBluetooth

#if DEBUG
/// Central that answers nothing, letting the real `SensorService` run without a radio.
final class InertBluetoothService: BluetoothServiceType {
    var delegate: (any CBCentralManagerDelegate)?

    func stopScan() {}
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {}
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] { [] }
    func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {}
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {}
}
#endif
