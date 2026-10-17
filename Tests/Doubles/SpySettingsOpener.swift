//
//  SpySettingsOpener.swift
//  tests
//
//  Created by Ondrej Hanak on 22.09.2026.
//

@testable import BLE_HR

@MainActor
final class SpySettingsOpener: SettingsOpenerType {
    private(set) var openCallCount = 0

    func open() {
        openCallCount += 1
    }
}
