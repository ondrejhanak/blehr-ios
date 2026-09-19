//
//  DiscoveredSensorRegistry.swift
//  blehr
//
//  Created by Ondrej Hanak on 19.09.2026.
//

import Foundation

/// Tracks sensors seen while scanning and forgets the ones that stopped advertising.
struct DiscoveredSensorRegistry: Equatable {
    private struct Entry: Equatable {
        let sensor: DiscoveredSensor
        let lastSeen: Date
    }

    private var entries: [UUID: Entry] = [:]

    /// Visible sensors, strongest signal first. Ties break on identifier to keep the order stable
    /// across refreshes.
    var sensors: [DiscoveredSensor] {
        entries.values
            .map(\.sensor)
            .sorted { ($0.rssi, $0.id.uuidString) > ($1.rssi, $1.id.uuidString) }
    }

    mutating func removeAll() {
        entries.removeAll()
    }

    /// - Returns: `true` when the visible list changed as a result.
    @discardableResult
    mutating func record(_ sensor: DiscoveredSensor, at date: Date) -> Bool {
        let previous = entries[sensor.id]?.sensor
        entries[sensor.id] = Entry(sensor: sensor, lastSeen: date)
        return previous != sensor
    }

    /// Drops sensors not heard from within `timeout` before `date`.
    /// - Returns: `true` when the visible list changed as a result.
    @discardableResult
    mutating func prune(olderThan timeout: TimeInterval, at date: Date) -> Bool {
        let remaining = entries.filter { date.timeIntervalSince($0.value.lastSeen) <= timeout }
        guard remaining.count != entries.count else { return false }
        entries = remaining
        return true
    }
}
