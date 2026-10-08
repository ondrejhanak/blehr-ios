//
//  PreviewSensorService.swift
//  blehr
//
//  Created by Ondrej Hanak on 07.10.2026.
//

import Combine
import Foundation

#if DEBUG
/// Reports one fixed state and never touches CoreBluetooth, so previews can render each case.
final class PreviewSensorService: SensorServiceType {
    private let stateSubject: CurrentValueSubject<SensorState, Never>

    var state: AnyPublisher<SensorState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(state: SensorState) {
        stateSubject = CurrentValueSubject(state)
    }

    func connect(id: DiscoveredSensor.ID) {}
    func disconnect() {}
}
#endif
