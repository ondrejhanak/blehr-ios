//
//  HeartRateViewModel.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import Combine
import UIKit

@MainActor
final class HeartRateViewModel: ObservableObject {
    private var sensorService: SensorServiceType
    private var cancellables = Set<AnyCancellable>()

    @Published var state: SensorState = .idle
    @Published var heartbeatPulse = false

    // MARK: - Lifecycle

    init(sensorService: SensorServiceType) {
        self.sensorService = sensorService
        setupObservation()
    }

    // MARK: - Methods

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
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
                if state == .idle {
                    self?.sensorService.scan()
                }
                if case .connected = state {
                    self?.heartbeatPulse.toggle()
                }
            }
            .store(in: &cancellables)
    }
}
