<p align="center">
<img src="icon.png" alt="App icon">
</p>

# BLE Heart Rate Monitor Demo

An iOS demo app showcasing **Bluetooth Low Energy** communication using SwiftUI, Combine, and CoreBluetooth.  
This project connects to a BLE heart rate sensor and displays real-time BPM values with animated feedback.

There is also a companion [ESP32 HR Simulator](https://github.com/ondrejhanak/blehr-sim) for easier testing, especially of 16-bit values as described below.

## Features

- Scans for BLE peripherals advertising the **Heart Rate Service** (`UUID 0x180D`)
- Subscribes to the **Heart Rate Measurement** characteristic (`UUID 0x2A37`)
- Displays incoming heart rate values with heartbeat animation
- Handles both **8-bit and 16-bit heart rate formats**, as specified in the [Heart Rate Profile](https://www.bluetooth.com/specifications/specs/html/?src=HRS_v1.0/out/en/index-en.html#UUID-967df1d3-6c3f-f480-6ac4-dc1ed6444fca)
- Written in **Swift 5** with **Complete Strict Concurrency Checking**

## Requirements

- iOS 16.0+
- Real iOS device (BLE is not available in the simulator)
- Heart rate monitor supporting BLE (some Garmin models are ANT+ only) or the [simulator](https://github.com/ondrejhanak/blehr-sim)

## Screen Recording

![App screenrecording](app.gif)
