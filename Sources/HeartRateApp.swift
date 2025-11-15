//
//  HeartRateApp.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

@main
struct HeartRateApp: App {
    var body: some Scene {
        WindowGroup {
            if isProduction {
                let viewModel = HeartRateViewModel()
                HeartRateView(viewModel: viewModel)
            }
        }
    }

    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
