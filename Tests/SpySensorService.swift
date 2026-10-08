//
//  SpySensorService.swift
//  tests
//
//  Created by Ondrej Hanak on 08.10.2026.
//

import Combine
import Foundation
@testable import BLE_HR

final class SpySensorService: SensorServiceType {
    private let stateSubject: CurrentValueSubject<SensorState, Never>

    private(set) var connectedIDs: [DiscoveredSensor.ID] = []
    private(set) var disconnectCallCount = 0

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(state: SensorState) {
        stateSubject = CurrentValueSubject(state)
    }

    func send(_ state: SensorState) {
        stateSubject.send(state)
    }

    func connect(id: DiscoveredSensor.ID) {
        connectedIDs.append(id)
    }

    func disconnect() {
        disconnectCallCount += 1
    }
}
