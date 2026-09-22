//
//  SensorService.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import CoreBluetooth
import Combine

protocol SensorServiceType: AnyObject {
    /// Current state, replayed to new subscribers.
    var state: AnyPublisher<SensorState, Never> { get }

    func connect(id: DiscoveredSensor.ID)
    func disconnect()
}

struct SensorConfiguration {
    /// How long a sensor stays listed after it was last heard from.
    var discoveryTimeout: TimeInterval = 5
    /// Upper bound on how often the scanning list is republished.
    var listRefreshInterval: TimeInterval = 1

    static let `default`: Self = .init()
}

final class SensorService: NSObject, SensorServiceType {
    private let configuration: SensorConfiguration
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let scanningListSubject = PassthroughSubject<[DiscoveredSensor], Never>()
    private let stateSubject = CurrentValueSubject<SensorState, Never>(.starting)
    private var centralManager: BluetoothServiceType
    private var heartRatePeripheral: CBPeripheral?
    private var registry = DiscoveredSensorRegistry()
    private var isPoweredOn = false
    private var isScanning = false
    private var pruningCancellable: AnyCancellable?

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle

    init(
        centralManager: BluetoothServiceType,
        configuration: SensorConfiguration = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.centralManager = centralManager
        self.configuration = configuration
        self.now = now
        super.init()
        centralManager.delegate = self

        scanningListSubject
            .throttle(for: .seconds(configuration.listRefreshInterval), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] sensors in
                // A throttled emission can land after the user already picked a sensor,
                // where publishing it would clobber `.connecting`.
                guard let self, self.isScanning else { return }
                self.stateSubject.send(.scanning(sensors))
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func connect(id: DiscoveredSensor.ID) {
        // Resolve the peripheral before tearing down the scan, so a failed lookup can
        // leave discovery running.
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [id]).first else {
            scan()
            return
        }
        stopScanning()
        stateSubject.send(.connecting)
        peripheral.delegate = self
        heartRatePeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        guard let heartRatePeripheral else { return }
        centralManager.cancelPeripheralConnection(heartRatePeripheral)
    }

    // MARK: - Private

    private func scan() {
        // Reachable from disconnect callbacks, which can arrive before the central reports
        // that it lost power.
        guard isPoweredOn else { return }
        stopScanning()
        registry.removeAll()

        isScanning = true
        // Entering the scanning state is not a list refresh, so it skips the throttle.
        stateSubject.send(.scanning([]))
        centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        pruningCancellable = Timer.publish(every: configuration.discoveryTimeout, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pruneStaleSensors()
            }
    }

    private func stopScanning() {
        isScanning = false
        pruningCancellable?.cancel()
        pruningCancellable = nil
        centralManager.stopScan()
    }

    private func pruneStaleSensors() {
        guard registry.prune(olderThan: configuration.discoveryTimeout, at: now()) else { return }
        scanningListSubject.send(registry.sensors)
    }

    private func releasePeripheral() {
        // Clearing the delegate stops late notifications from the old peripheral.
        heartRatePeripheral?.delegate = nil
        heartRatePeripheral = nil
    }
}

extension SensorService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isPoweredOn = central.state == .poweredOn
        guard isPoweredOn else {
            stopScanning()
            releasePeripheral()
            stateSubject.send(.disabled)
            return
        }
        scan()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        releasePeripheral()
        scan()
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
        let sensor = DiscoveredSensor(
            id: peripheral.identifier,
            name: peripheral.name,
            rssi: RSSI.intValue
        )
        guard registry.record(sensor, at: now()) else { return }
        scanningListSubject.send(registry.sensors)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        releasePeripheral()
        scan()
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
        guard let data = characteristic.value, let bpm = HeartRateParser.parse(data) else { return }
        let info = SensorInfo(
            id: peripheral.identifier,
            bpm: bpm,
            name: peripheral.name,
            timestamp: now()
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

    func connect(id: UUID) {}
    func disconnect() {}
}
#endif
