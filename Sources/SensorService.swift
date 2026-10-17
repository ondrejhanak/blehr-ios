//
//  SensorService.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import Combine
import Foundation

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

final class SensorService: SensorServiceType {
    private let central: BluetoothCentralType
    private let configuration: SensorConfiguration
    private let now: () -> Date
    private var cancellables = Set<AnyCancellable>()
    private let scanningListSubject = PassthroughSubject<[DiscoveredSensor], Never>()
    private let stateSubject = CurrentValueSubject<SensorState, Never>(.starting)
    private var registry = DiscoveredSensorRegistry()
    private var connectedSensorID: DiscoveredSensor.ID?
    private var isPoweredOn = false
    private var isScanning = false
    private var pruningCancellable: AnyCancellable?

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle

    init(
        central: BluetoothCentralType,
        configuration: SensorConfiguration,
        now: @escaping () -> Date
    ) {
        self.central = central
        self.configuration = configuration
        self.now = now

        scanningListSubject
            .throttle(for: .seconds(configuration.listRefreshInterval), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] sensors in
                // An advertisement already in flight when the scan stopped would otherwise
                // publish a list over `.connecting`.
                guard let self, self.isScanning else { return }
                self.stateSubject.send(.scanning(sensors))
            }
            .store(in: &cancellables)

        central.delegate = self
    }

    // MARK: - Methods

    func connect(id: DiscoveredSensor.ID) {
        stopScanning()
        // Sent before asking the central, which can report failure synchronously.
        stateSubject.send(.connecting)
        connectedSensorID = id
        central.connect(id: id)
    }

    func disconnect() {
        guard let connectedSensorID else { return }
        central.disconnect(id: connectedSensorID)
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
        central.startScanning()
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
        central.stopScanning()
    }

    private func pruneStaleSensors() {
        guard registry.prune(olderThan: configuration.discoveryTimeout, at: now()) else { return }
        scanningListSubject.send(registry.sensors)
    }
}

extension SensorService: BluetoothCentralDelegate {
    func centralDidChangeAvailability(to isAvailable: Bool) {
        isPoweredOn = isAvailable
        guard isAvailable else {
            stopScanning()
            connectedSensorID = nil
            stateSubject.send(.disabled)
            return
        }
        scan()
    }

    func centralDidDiscover(_ sensor: DiscoveredSensor) {
        guard registry.record(sensor, at: now()) else { return }
        scanningListSubject.send(registry.sensors)
    }

    func centralDidFailToConnect(to id: DiscoveredSensor.ID) {
        connectedSensorID = nil
        scan()
    }

    func centralDidDisconnect(from id: DiscoveredSensor.ID) {
        connectedSensorID = nil
        scan()
    }

    func centralDidReceiveMeasurement(_ data: Data, from id: DiscoveredSensor.ID, name: String?) {
        guard let bpm = HeartRateParser.parse(data) else { return }
        let info = SensorInfo(
            id: id,
            bpm: bpm,
            name: name,
            timestamp: now()
        )
        stateSubject.send(.connected(info))
    }
}
