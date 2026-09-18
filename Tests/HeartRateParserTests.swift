//
//  HeartRateParserTests.swift
//  tests
//
//  Created by Ondrej Hanak on 02.08.2025.
//

import Testing
import Foundation
@testable import BLE_HR

struct HeartRateParserTests {
    @Test(arguments:
            [
                (0,   [0x00, 0x00]),
                (5,   [0x00, 0x05]),
                (255, [0x00, 0xFF]),
                (256,  [0x01, 0x00, 0x01]),
                (1023, [0x01, 0xFF, 0x03]),
                // Flags beyond bit 0 (sensor contact, energy, RR) must not shift the BPM field.
                (72,   [0x06, 0x48]),
                (300,  [0x1F, 0x2C, 0x01]),
                // Trailing fields after the BPM are ignored.
                (60,   [0x00, 0x3C, 0x11, 0x22]),
            ]
    )
    func parseParsing(params: (Int, [UInt8])) {
        let bpm = HeartRateParser.parse(Data(params.1))
        #expect(bpm == params.0)
    }

    @Test(arguments:
            [
                [UInt8](), // no flags byte
                [0x00], // 8-bit format, BPM missing
                [0x01], // 16-bit format, BPM missing
                [0x01, 0xFF], // 16-bit format, high byte missing
            ]
    )
    func parseRejectsTruncatedPackets(bytes: [UInt8]) {
        #expect(HeartRateParser.parse(Data(bytes)) == nil)
    }
}
