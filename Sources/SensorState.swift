//
//  SensorState.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import Foundation

struct SensorInfo: Identifiable, Equatable {
    let id: UUID
    let bpm: Int
    let name: String?
    let timestamp: Date
}

struct DiscoveredSensor: Identifiable, Equatable {
    let id: UUID
    let name: String?
    let rssi: Int
}

struct SensorFailure: Equatable {
    enum Reason: Equatable {
        case couldNotConnect
    }

    let sensorName: String?
    let reason: Reason

    var message: String {
        switch reason {
        case .couldNotConnect:
            if let sensorName {
                return "Could not connect to \(sensorName)."
            }
            return "Could not connect to the sensor."
        }
    }
}

enum SensorState: Equatable {
    case starting
    case disabled
    case scanning([DiscoveredSensor])
    case connecting
    case connected(SensorInfo)
    case failed(SensorFailure)
}
