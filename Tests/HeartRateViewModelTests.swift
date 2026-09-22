//
//  HeartRateViewModelTests.swift
//  tests
//
//  Created by Ondrej Hanak on 22.09.2026.
//

import Testing
@testable import BLE_HR

@MainActor
struct HeartRateViewModelTests {
    @Test
    func openSettingsAsksTheOpener() {
        let opener = SpySettingsOpener()
        let viewModel = HeartRateViewModel(sensorService: PreviewSensorService(state: .starting), settingsOpener: opener)
        viewModel.openSettings()
        #expect(opener.openCallCount == 1)
    }
}
