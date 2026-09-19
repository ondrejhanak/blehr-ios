//
//  DiscoveredSensorRegistryTests.swift
//  tests
//
//  Created by Ondrej Hanak on 19.09.2026.
//

import Testing
import Foundation
@testable import BLE_HR

struct DiscoveredSensorRegistryTests {
    private let start = Date(timeIntervalSince1970: 1_000)
    private let timeout: TimeInterval = 5

    private func sensor(_ rssi: Int, id: UUID = UUID()) -> DiscoveredSensor {
        DiscoveredSensor(id: id, name: "Sensor \(rssi)", rssi: rssi)
    }

    @Test
    func listsStrongestSignalFirst() {
        var registry = DiscoveredSensorRegistry()
        let weak = sensor(-80)
        let strong = sensor(-40)
        let middle = sensor(-60)
        registry.record(weak, at: start)
        registry.record(strong, at: start)
        registry.record(middle, at: start)
        #expect(registry.sensors == [strong, middle, weak])
    }

    @Test
    func reportsNoChangeForRepeatedIdenticalAdvertisement() {
        var registry = DiscoveredSensorRegistry()
        let advertised = sensor(-50)
        #expect(registry.record(advertised, at: start) == true)
        #expect(registry.record(advertised, at: start.addingTimeInterval(1)) == false)
    }

    @Test
    func reportsChangeWhenSignalStrengthMoves() {
        var registry = DiscoveredSensorRegistry()
        let id = UUID()
        registry.record(sensor(-50, id: id), at: start)
        #expect(registry.record(sensor(-55, id: id), at: start.addingTimeInterval(1)) == true)
        #expect(registry.sensors.map(\.rssi) == [-55])
    }

    @Test
    func pruneDropsSensorsPastTheTimeout() {
        var registry = DiscoveredSensorRegistry()
        let stale = sensor(-50)
        let fresh = sensor(-60)
        registry.record(stale, at: start)
        registry.record(fresh, at: start.addingTimeInterval(timeout))
        #expect(registry.prune(olderThan: timeout, at: start.addingTimeInterval(timeout * 1.5)) == true)
        #expect(registry.sensors == [fresh])
    }

    @Test
    func pruneKeepsSensorSeenExactlyAtTheTimeout() {
        var registry = DiscoveredSensorRegistry()
        let borderline = sensor(-50)
        registry.record(borderline, at: start)
        #expect(registry.prune(olderThan: timeout, at: start.addingTimeInterval(timeout)) == false)
        #expect(registry.sensors == [borderline])
    }

    @Test
    func pruneReportsNoChangeWhenNothingExpired() {
        var registry = DiscoveredSensorRegistry()
        registry.record(sensor(-50), at: start)
        #expect(registry.prune(olderThan: timeout, at: start.addingTimeInterval(timeout / 2)) == false)
    }

    @Test
    func removeAllClearsTheList() {
        var registry = DiscoveredSensorRegistry()
        registry.record(sensor(-50), at: start)
        registry.removeAll()
        #expect(registry.sensors.isEmpty)
    }
}
