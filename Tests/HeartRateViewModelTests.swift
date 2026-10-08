//
//  HeartRateViewModelTests.swift
//  tests
//
//  Created by Ondrej Hanak on 22.09.2026.
//

import Testing
import Foundation
@testable import BLE_HR

private let sensor = DiscoveredSensor(id: UUID(), name: "Chest Strap", rssi: -55)
private let measurement = SensorInfo(id: UUID(), bpm: 72, name: "Chest Strap", timestamp: Date(timeIntervalSince1970: 1_000))

/// Every case of the state machine, so a view model that hardcoded any single one would fail.
private let allSensorStates: [SensorState] = [
    .starting,
    .disabled,
    .scanning([]),
    .scanning([sensor]),
    .connecting,
    .connected(measurement),
]

@MainActor
struct HeartRateViewModelTests {
    /// The view model schedules delivery on the main queue, so queued work has to run before
    /// the published state reflects what the service sent.
    private func flushMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    private func makeViewModel(
        service: SpySensorService,
        opener: SpySettingsOpener = SpySettingsOpener()
    ) -> HeartRateViewModel {
        HeartRateViewModel(sensorService: service, settingsOpener: opener)
    }

    @Test(arguments: allSensorStates)
    func adoptsServiceStateOnCreation(state: SensorState) async {
        let service = SpySensorService(state: state)
        let viewModel = makeViewModel(service: service)
        await flushMainQueue()
        #expect(viewModel.state == state)
    }

    @Test(arguments: allSensorStates)
    func forwardsStateSentAfterCreation(state: SensorState) async {
        let service = SpySensorService(state: .starting)
        let viewModel = makeViewModel(service: service)
        await flushMainQueue()

        service.send(state)
        await flushMainQueue()
        #expect(viewModel.state == state)
    }

    @Test
    func forwardsEveryMeasurementWhileConnected() async {
        let service = SpySensorService(state: .starting)
        let viewModel = makeViewModel(service: service)
        let id = UUID()

        for bpm in [60, 61, 62] {
            service.send(.connected(SensorInfo(id: id, bpm: bpm, name: "Chest Strap", timestamp: .now)))
            await flushMainQueue()
            guard case let .connected(info) = viewModel.state else {
                Issue.record("expected connected state, got \(viewModel.state)")
                return
            }
            #expect(info.bpm == bpm)
        }
    }

    @Test
    func connectForwardsIdentifierToService() {
        let service = SpySensorService(state: .starting)
        let viewModel = makeViewModel(service: service)
        let id = UUID()
        viewModel.connectSensor(id: id)
        #expect(service.connectedIDs == [id])
    }

    @Test
    func disconnectForwardsToService() {
        let service = SpySensorService(state: .starting)
        let viewModel = makeViewModel(service: service)
        viewModel.disconnect()
        #expect(service.disconnectCallCount == 1)
    }

    @Test
    func openSettingsAsksTheOpener() {
        let opener = SpySettingsOpener()
        let viewModel = makeViewModel(service: SpySensorService(state: .starting), opener: opener)
        viewModel.openSettings()
        #expect(opener.openCallCount == 1)
    }
}
