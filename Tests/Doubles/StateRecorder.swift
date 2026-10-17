//
//  StateRecorder.swift
//  tests
//
//  Created by Ondrej Hanak on 17.10.2026.
//

import Combine
@testable import BLE_HR

/// Collects everything a sensor service publishes, so a test can assert on the latest state
/// or on the whole sequence.
final class StateRecorder {
    private(set) var states: [SensorState] = []
    private var cancellable: AnyCancellable?

    var last: SensorState? { states.last }

    init(_ service: SensorServiceType) {
        cancellable = service.state.sink { [weak self] state in
            self?.states.append(state)
        }
    }
}
