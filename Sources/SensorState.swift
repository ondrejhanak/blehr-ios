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

enum SensorState: Equatable {
    case starting
    case disabled
    case scanning([DiscoveredSensor])
    case connecting
    case connected(SensorInfo)
}
