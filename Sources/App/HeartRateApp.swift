//
//  HeartRateApp.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

@main
@MainActor
struct HeartRateApp: App {
    @StateObject private var viewModel = CompositionRoot.makeHeartRateViewModel()

    var body: some Scene {
        WindowGroup {
            HeartRateView(viewModel: viewModel)
        }
    }
}
