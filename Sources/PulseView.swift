//
//  PulseView.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import SwiftUI

struct PulseView: View {
    @State private var heartbeatPulse = false
    var info: SensorInfo

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .scaleEffect(heartbeatPulse ? 1.2 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.3), value: heartbeatPulse)
            Text(info.bpm, format: .number)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundColor(.red)
        .onChange(of: info.timestamp) { _ in
            heartbeatPulse.toggle()
        }
        Text(info.name ?? info.id.uuidString)
            .font(.caption)
            .foregroundColor(.gray)
    }
}

#if DEBUG
#Preview {
    PulseView(info: .init(id: UUID(), bpm: 123, name: "Preview Sensor", timestamp: .now))
}
#endif
