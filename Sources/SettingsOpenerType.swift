//
//  SettingsOpenerType.swift
//  blehr
//
//  Created by Ondrej Hanak on 22.09.2026.
//

import UIKit

/// Takes the user to this app's page in the system Settings app.
@MainActor
protocol SettingsOpenerType {
    func open()
}

@MainActor
struct SystemSettingsOpener: SettingsOpenerType {
    func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
