//
//  HeartRateParser.swift
//  blehr
//
//  Created by Ondrej Hanak on 02.08.2025.
//

import Foundation

struct HeartRateParser {
    /// Parses data of a 2A37 notification.
    /// - Parameter data: The raw Data from the characteristic.
    /// - Returns: The decoded BPM, or `nil` when the packet is too short to carry one.
    static func parse(_ data: Data) -> Int? {
        let byteArray = [UInt8](data)
        guard let flag = byteArray.first else { return nil }
        if flag & 0x01 == 0 {
            guard byteArray.count >= 2 else { return nil }
            return Int(byteArray[1]) // UInt8
        } else {
            guard byteArray.count >= 3 else { return nil }
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8) // UInt16 little endian
        }
    }
}
