//
//  PulseView.swift
//  blehr
//
//  Created by Ondrej Hanak on 31.07.2025.
//

import SwiftUI

struct PulseView: View {
    private enum Beat: CaseIterable {
        case rest, contract

        var scale: CGFloat {
            switch self {
            case .rest: 1.0
            case .contract: 1.22
            }
        }
    }

    /// Fixed, so a fast beat stays legible instead of shrinking with the interval.
    private let contraction: Double = 0.14

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var info: SensorInfo

    /// Seconds between beats at the reported rate. Clamped because a malformed packet can
    /// report zero, and because nothing above 220 is a plausible heart rate.
    private var beatInterval: Double {
        60.0 / Double(min(max(info.bpm, 30), 220))
    }

    var body: some View {
        HStack(spacing: 10) {
            heart
            Text(info.bpm, format: .number)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundColor(.red)
        Text(info.name ?? info.id.uuidString)
            .font(.caption)
            .foregroundColor(.gray)
    }

    @ViewBuilder
    private var heart: some View {
        let image = Image(systemName: "heart.fill").font(.system(size: 32))
        if reduceMotion {
            image
        } else {
            image.phaseAnimator(Beat.allCases) { heart, beat in
                heart.scaleEffect(beat.scale)
            } animation: { beat in
                switch beat {
                case .contract: .easeOut(duration: contraction)
                case .rest: .easeIn(duration: beatInterval - contraction)
                }
            }
        }
    }
}

#if DEBUG
#Preview("resting") {
    PulseView(info: .init(id: UUID(), bpm: 62, name: "Chest Strap", timestamp: .now))
}

#Preview("exertion") {
    PulseView(info: .init(id: UUID(), bpm: 168, name: "Chest Strap", timestamp: .now))
}
#endif
