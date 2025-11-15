//
//  HeartRateView.swift
//  blehr
//
//  Created by Ondrej Hanak on 29.07.2025.
//

import SwiftUI

struct HeartRateView: View {
    @StateObject var viewModel: HeartRateViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Heart Rate")
                .font(.title)
            switch viewModel.state {
            case .disabled:
                disabledView
            case .idle:
                EmptyView() // no visual representation
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
#Preview("connected") {
    let info = SensorInfo(id: UUID(), bpm: 123, name: "Preview Sensor", timestamp: .now)
    let service = PreviewSensorService(state: .connected(info))
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("disabled") {
    let service = PreviewSensorService(state: .disabled)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("idle") {
    let service = PreviewSensorService(state: .idle)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("scanning - empty") {
    let service = PreviewSensorService(state: .scanning([]))
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}

#Preview("connecting") {
    let service = PreviewSensorService(state: .connecting)
    return HeartRateView(viewModel: HeartRateViewModel(sensorService: service))
}
#endif
