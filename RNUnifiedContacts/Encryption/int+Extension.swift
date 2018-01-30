//
//  int+Extension.swift
//  CryptDemo
//
//  Created by altaf on 12/01/2018.
//  Copyright © 2018 altaf. All rights reserved.
//

import Foundation
public protocol _UInt8Type {}
extension UInt8: _UInt8Type {}

/** casting */
extension UInt8 {
    
    /** cast because UInt8(<UInt32>) because std initializer crash if value is > byte */
    static func with(value: UInt64) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }
    
    static func with(value: UInt32) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }
    
    static func with(value: UInt16) -> UInt8 {
        let tmp = value & 0xff
        return UInt8(tmp)
    }
}
extension UInt8 {
    
    init(bits: [Bit]) {
        self.init(integerFrom(bits) as UInt8)
    }
    
    /** array of bits */
    public func bits() -> [Bit] {
        let totalBitsCount = MemoryLayout<UInt8>.size * 8
        
        var bitsArray = [Bit](repeating: Bit.zero, count: totalBitsCount)
        
        for j in 0..<totalBitsCount {
            let bitVal: UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
            let check = self & bitVal
            
            if check != 0 {
                bitsArray[j] = Bit.one
            }
        }
        return bitsArray
    }
    
    public func bits() -> String {
        var s = String()
        let arr: [Bit] = bits()
        for idx in arr.indices {
            s += (arr[idx] == Bit.one ? "1" : "0")
            if idx.advanced(by: 1) % 8 == 0 { s += " " }
        }
        return s
    }
}
protocol _UInt32Type {}
extension UInt32: _UInt32Type {}

/** array of bytes */
extension UInt32 {
    
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt32(bytes: bytes, fromIndex: bytes.startIndex)
    }
    
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }
        
        let count = bytes.count
        
        let val0 = count > 0 ? UInt32(bytes[index.advanced(by: 0)]) << 24 : 0
        let val1 = count > 1 ? UInt32(bytes[index.advanced(by: 1)]) << 16 : 0
        let val2 = count > 2 ? UInt32(bytes[index.advanced(by: 2)]) << 8 : 0
        let val3 = count > 3 ? UInt32(bytes[index.advanced(by: 3)]) : 0
        
        self = val0 | val1 | val2 | val3
    }
}
extension UInt64 {
    
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt64(bytes: bytes, fromIndex: bytes.startIndex)
    }
    
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }
        
        let count = bytes.count
        
        let val0 = count > 0 ? UInt64(bytes[index.advanced(by: 0)]) << 56 : 0
        let val1 = count > 0 ? UInt64(bytes[index.advanced(by: 1)]) << 48 : 0
        let val2 = count > 0 ? UInt64(bytes[index.advanced(by: 2)]) << 40 : 0
        let val3 = count > 0 ? UInt64(bytes[index.advanced(by: 3)]) << 32 : 0
        let val4 = count > 0 ? UInt64(bytes[index.advanced(by: 4)]) << 24 : 0
        let val5 = count > 0 ? UInt64(bytes[index.advanced(by: 5)]) << 16 : 0
        let val6 = count > 0 ? UInt64(bytes[index.advanced(by: 6)]) << 8 : 0
        let val7 = count > 0 ? UInt64(bytes[index.advanced(by: 7)]) : 0
        
        self = val0 | val1 | val2 | val3 | val4 | val5 | val6 | val7
    }
}
extension UInt16 {
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt16(bytes: bytes, fromIndex: bytes.startIndex)
    }
    
    @_specialize(exported: true, where T == ArraySlice<UInt8>)
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }
        
        let count = bytes.count
        
        let val0 = count > 0 ? UInt16(bytes[index.advanced(by: 0)]) << 8 : 0
        let val1 = count > 1 ? UInt16(bytes[index.advanced(by: 1)]) : 0
        
        self = val0 | val1
    }
}
extension Bit {
    func inverted() -> Bit {
        return self == .zero ? .one : .zero
    }
}
