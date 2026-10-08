//
//  HeartRateView.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

struct HeartRateView: View {
    @ObservedObject var viewModel: HeartRateViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Heart Rate")
                .font(.title)
            switch viewModel.state {
            case .starting:
                EmptyView() // nothing reported yet
            case .disabled:
                disabledView
            case let .scanning(sensors):
                scanningView(sensors)
            case .connecting:
                ProgressView()
            case let .connected(info):
                PulseView(info: info)
                Button("Disconnect") {
                    viewModel.disconnect()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .padding(.top)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var disabledView: some View {
        Text("Please enable Bluetooth to see the heart rate.")
            .font(.body)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
        Button("Settings") {
            viewModel.openSettings()
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private func scanningView(_ sensors: [DiscoveredSensor]) -> some View {
        if sensors.isEmpty {
            ProgressView()
            Text("Searching for sensors...")
                .font(.caption)
                .foregroundColor(.gray)
        } else {
            List(sensors) { sensor in
                Button {
                    viewModel.connectSensor(id: sensor.id)
                } label: {
                    HStack {
                        Text(sensor.name ?? sensor.id.uuidString)
                        Spacer()
                        Text("\(sensor.rssi) dBm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#if DEBUG
@MainActor
private func previewView(_ state: SensorState) -> HeartRateView {
    HeartRateView(
        viewModel: HeartRateViewModel(
            sensorService: PreviewSensorService(state: state),
            settingsOpener: SystemSettingsOpener()
        )
    )
}

#Preview("starting") {
    previewView(.starting)
}

#Preview("disabled") {
    previewView(.disabled)
}

#Preview("scanning - empty") {
    previewView(.scanning([]))
}

#Preview("scanning - sensors") {
    previewView(.scanning([
        DiscoveredSensor(id: UUID(), name: "Chest Strap", rssi: -48),
        DiscoveredSensor(id: UUID(), name: nil, rssi: -71),
    ]))
}

#Preview("connecting") {
    previewView(.connecting)
}

#Preview("connected") {
    previewView(.connected(SensorInfo(id: UUID(), bpm: 123, name: "Preview Sensor", timestamp: .now)))
}
#endif
