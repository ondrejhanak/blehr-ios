//
//  SensorServiceTests.swift
//  tests
//
//  Created by Ondrej Hanak on 17.10.2026.
//

import Testing
import Foundation
@testable import BLE_HR

struct SensorServiceTests {
    private let refreshInterval: TimeInterval = 0.05
    private let sensor = DiscoveredSensor(id: UUID(), name: "Chest Strap", rssi: -55)

    /// An 8-bit measurement of 72 bpm: flags byte then the value.
    private let measurement = Data([0x00, 0x48])

    private func makeService(
        central: FakeBluetoothCentral,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 1_000) }
    ) -> SensorService {
        var configuration = SensorConfiguration.default
        configuration.listRefreshInterval = refreshInterval
        return SensorService(central: central, configuration: configuration, now: now)
    }

    /// Lets the throttled scanning list emit, which takes at least one refresh interval.
    private func waitForListRefresh() async throws {
        try await Task.sleep(nanoseconds: UInt64(refreshInterval * 4 * 1_000_000_000))
    }

    // MARK: - Availability

    @Test
    func startsScanningWhenTheCentralBecomesAvailable() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)

        service.centralDidChangeAvailability(to: true)

        #expect(central.isScanning)
        #expect(recorder.last == .scanning([]))
    }

    @Test
    func stopsScanningAndReportsDisabledWhenAvailabilityIsLost() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)

        service.centralDidChangeAvailability(to: false)

        #expect(central.isScanning == false)
        #expect(recorder.last == .disabled)
    }

    @Test
    func doesNotScanWhileTheCentralIsUnavailable() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)

        // A disconnect can arrive before the central reports that it lost power.
        service.centralDidDisconnect(from: sensor.id)

        #expect(central.startScanningCallCount == 0)
    }

    @Test
    func doesNotScanWhenADisconnectFollowsPowerLoss() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)
        service.centralDidChangeAvailability(to: false)
        let countAfterPowerOff = central.startScanningCallCount

        service.centralDidDisconnect(from: sensor.id)

        #expect(central.startScanningCallCount == countAfterPowerOff)
        #expect(recorder.last == .disabled)
    }

    // MARK: - Connecting

    @Test
    func connectingStopsTheScanAndReportsConnecting() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)

        service.connect(id: sensor.id)

        #expect(central.connectedIDs == [sensor.id])
        #expect(central.isScanning == false)
        #expect(recorder.last == .connecting)
    }

    @Test
    func returnsToScanningWhenConnectingFails() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)
        service.connect(id: sensor.id)

        service.centralDidFailToConnect(to: sensor.id)

        #expect(recorder.last == .scanning([]))
        #expect(central.isScanning)
    }

    @Test
    func returnsToScanningAfterDisconnecting() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)
        service.connect(id: sensor.id)

        service.centralDidDisconnect(from: sensor.id)

        #expect(recorder.last == .scanning([]))
        #expect(central.isScanning)
    }

    @Test
    func disconnectAsksTheCentralForTheConnectedSensor() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        service.centralDidChangeAvailability(to: true)
        service.connect(id: sensor.id)

        service.disconnect()

        #expect(central.disconnectedIDs == [sensor.id])
    }

    @Test
    func disconnectDoesNothingWithoutAConnection() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        service.centralDidChangeAvailability(to: true)

        service.disconnect()

        #expect(central.disconnectedIDs.isEmpty)
    }

    // MARK: - Measurements

    @Test
    func publishesParsedMeasurements() {
        let central = FakeBluetoothCentral()
        let timestamp = Date(timeIntervalSince1970: 2_000)
        let service = makeService(central: central, now: { timestamp })
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)
        service.connect(id: sensor.id)

        service.centralDidReceiveMeasurement(measurement, from: sensor.id, name: sensor.name)

        #expect(recorder.last == .connected(SensorInfo(id: sensor.id, bpm: 72, name: sensor.name, timestamp: timestamp)))
    }

    @Test
    func ignoresMalformedMeasurements() {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)
        service.connect(id: sensor.id)

        // Flags claim an 8-bit value, but no value follows.
        service.centralDidReceiveMeasurement(Data([0x00]), from: sensor.id, name: sensor.name)

        #expect(recorder.last == .connecting)
    }

    // MARK: - Discovery

    @Test
    func publishesDiscoveredSensors() async throws {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)

        service.centralDidDiscover(sensor)
        try await waitForListRefresh()

        #expect(recorder.last == .scanning([sensor]))
    }

    @Test
    func aLateDiscoveryDoesNotOverwriteConnecting() async throws {
        let central = FakeBluetoothCentral()
        let service = makeService(central: central)
        let recorder = StateRecorder(service)
        service.centralDidChangeAvailability(to: true)

        service.connect(id: sensor.id)
        // Stopping a scan does not stop an advertisement already on its way.
        service.centralDidDiscover(sensor)
        try await waitForListRefresh()

        #expect(recorder.last == .connecting)
    }
}
