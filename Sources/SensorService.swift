//
//  SensorService.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import CoreBluetooth
import Combine

protocol SensorServiceType: AnyObject {
    var state: AnyPublisher<SensorState, Never> { get }

    func scan()
    func connect(id: DiscoveredSensor.ID)
    func disconnect()
}

final class SensorService: NSObject, SensorServiceType {
    let sensorDiscoveryTimeout: TimeInterval = 5

    private var cancellables = Set<AnyCancellable>()
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let scanningListSubject = PassthroughSubject<[DiscoveredSensor], Never>()
    private let stateSubject = PassthroughSubject<SensorState, Never>()
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    private var discovered: [UUID: (sensor: DiscoveredSensor, lastSeen: Date)] = [:]
    private var cleanupCancellable: AnyCancellable?

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        scanningListSubject
            .throttle(for: .milliseconds(1000), scheduler: RunLoop.main, latest: true) // throttle rapid refresh
            .sink { [weak self] sensors in
                self?.stateSubject.send(.scanning(sensors))
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func scan() {
        discovered.removeAll()
        publishScanningList()
        centralManager.stopScan()
        cleanupCancellable?.cancel()
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        cleanupCancellable = Timer.publish(every: sensorDiscoveryTimeout, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pruneStaleSensors()
            }
    }

    func connect(id: DiscoveredSensor.ID) {
        stateSubject.send(.connecting)
        cleanupCancellable?.cancel()
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [id])
        if let peripheral = peripherals.first {
            peripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
            heartRatePeripheral = peripheral
        } else {
            stateSubject.send(.idle)
        }
    }

    func disconnect() {
        guard let heartRatePeripheral else { return }
        centralManager.cancelPeripheralConnection(heartRatePeripheral)
    }

    // MARK: - Private

    private func pruneStaleSensors() {
        let now = Date()
        discovered = discovered.filter { now.timeIntervalSince($0.value.lastSeen) <= sensorDiscoveryTimeout }
        publishScanningList()
    }

    private func publishScanningList() {
        let sensors = discovered.values
            .map { $0.sensor }
            .sorted(by: { $0.rssi > $1.rssi })
        scanningListSubject.send(sensors)
    }
}

extension SensorService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            stateSubject.send(.idle)
        } else {
            stateSubject.send(.disabled)
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        stateSubject.send(.idle)
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
        let model = DiscoveredSensor(
            id: peripheral.identifier,
            name: peripheral.name,
            rssi: RSSI.intValue
        )
        discovered[peripheral.identifier] = (sensor: model, lastSeen: Date())
        publishScanningList()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        stateSubject.send(.idle)
    }
}

extension SensorService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let service = services.first(where: { $0.uuid == heartRateServiceUUID }) else { return }
        peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        guard let characteristic = characteristics.first(where: { $0.uuid == heartRateMeasurementUUID }) else { return }
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let bpm = HeartRateParser.parse(data)
        let info = SensorInfo(
            id: peripheral.identifier,
            bpm: bpm,
            name: peripheral.name,
            timestamp: .now
        )
        stateSubject.send(.connected(info))
    }
}

#if DEBUG
final class PreviewSensorService: SensorServiceType {
    private let stateSubject: CurrentValueSubject<SensorState, Never>

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(state: SensorState) {
        stateSubject = CurrentValueSubject(state)
    }

    func scan() {}
    func connect(id: UUID) {}
    func disconnect() {}
}
#endif
