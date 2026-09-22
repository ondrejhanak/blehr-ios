//
//  HeartRateViewModel.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import Combine
import Foundation

@MainActor
final class HeartRateViewModel: ObservableObject {
    private let sensorService: SensorServiceType
    private let settingsOpener: SettingsOpenerType
    private var cancellables = Set<AnyCancellable>()

    @Published var state: SensorState = .starting

    // MARK: - Lifecycle

    init(sensorService: SensorServiceType, settingsOpener: SettingsOpenerType) {
        self.sensorService = sensorService
        self.settingsOpener = settingsOpener
        setupObservation()
    }

    // MARK: - Methods

    func openSettings() {
        settingsOpener.open()
    }

    func connectSensor(id: DiscoveredSensor.ID) {
        sensorService.connect(id: id)
    }

    func disconnect() {
        sensorService.disconnect()
    }

    // MARK: - Private

    private func setupObservation() {
        sensorService.state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
    }
}
