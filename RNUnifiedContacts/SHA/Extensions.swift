#if os(Linux) || os(Android) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif

public enum Bit: Int {
    case zero
    case one
}

extension String {
    
    public var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    public func sha224() -> String {
        return bytes.sha224().toHexString()
    }
    
    public func sha256() -> String {
        return bytes.sha256().toHexString()
    }
    
    public func sha384() -> String {
        return bytes.sha384().toHexString()
    }
    
    public func sha512() -> String {
        return bytes.sha512().toHexString()
    }
}

/* array of bits */
extension Int {
    init(bits: [Bit]) {
        self.init(bitPattern: integerFrom(bits) as UInt)
    }
}

extension FixedWidthInteger {
    @_transparent
    func bytes(totalBytes: Int = MemoryLayout<Self>.size) -> Array<UInt8> {
        return arrayOfBytes(value: self, length: totalBytes)
        // TODO: adjust bytes order
        // var value = self
        // return withUnsafeBytes(of: &value, Array.init).reversed()
    }
}
extension Updatable {
    public mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false, output: (_ bytes: Array<UInt8>) -> Void) throws {
        let processed = try update(withBytes: bytes, isLast: isLast)
        if !processed.isEmpty {
            output(processed)
        }
    }
    public mutating func finish(withBytes bytes: ArraySlice<UInt8>) throws -> Array<UInt8> {
        return try update(withBytes: bytes, isLast: true)
    }
    public mutating func finish() throws -> Array<UInt8> {
        return try update(withBytes: [], isLast: true)
    }
    public mutating func finish(withBytes bytes: ArraySlice<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws {
        let processed = try update(withBytes: bytes, isLast: true)
        if !processed.isEmpty {
            output(processed)
        }
    }
    public mutating func finish(output: (Array<UInt8>) -> Void) throws {
        try finish(withBytes: [], output: output)
    }
}

extension Updatable {
    public mutating func update(withBytes bytes: Array<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        return try update(withBytes: bytes.slice, isLast: isLast)
    }
    public mutating func update(withBytes bytes: Array<UInt8>, isLast: Bool = false, output: (_ bytes: Array<UInt8>) -> Void) throws {
        return try update(withBytes: bytes.slice, isLast: isLast, output: output)
    }
    public mutating func finish(withBytes bytes: Array<UInt8>) throws -> Array<UInt8> {
        return try finish(withBytes: bytes.slice)
    }
    public mutating func finish(withBytes bytes: Array<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws {
        return try finish(withBytes: bytes.slice, output: output)
    }
}
public extension Array where Element == UInt8 {
    public func toHexString() -> String {
        return `lazy`.reduce("") {
            var s = String($1, radix: 16)
            if s.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}

public extension Array where Element == UInt8 {
    
    public func sha224() -> [Element] {
        return Digest.sha224(self)
    }
    
    public func sha256() -> [Element] {
        return Digest.sha256(self)
    }
    
    public func sha384() -> [Element] {
        return Digest.sha384(self)
    }
    
    public func sha512() -> [Element] {
        return Digest.sha512(self)
    }
    
    public func sha2(_ variant: SHA2.Variant) -> [Element] {
        return Digest.sha2(self, variant: variant)
    }
}
// MARK: Public interface
public extension Checksum {
    
    /// Calculate CRC32
    ///
    /// - parameter message: Message
    /// - parameter seed:    Seed value (Optional)
    /// - parameter reflect: is reflect (default true)
    ///
    /// - returns: Calculated code
    static func crc32(_ message: Array<UInt8>, seed: UInt32? = nil, reflect: Bool = true) -> UInt32 {
        return Checksum().crc32(message, seed: seed, reflect: reflect)
    }
    
    /// Calculate CRC16
    ///
    /// - parameter message: Message
    /// - parameter seed:    Seed value (Optional)
    ///
    /// - returns: Calculated code
    static func crc16(_ message: Array<UInt8>, seed: UInt16? = nil) -> UInt16 {
        return Checksum().crc16(message, seed: seed)
    }
}


extension Collection where Self.Element == UInt8, Self.Index == Int {
    
    // Big endian order
    func toUInt32Array() -> Array<UInt32> {
        if isEmpty {
            return []
        }
        
        var result = Array<UInt32>(reserveCapacity: 16)
        for idx in stride(from: startIndex, to: endIndex, by: 4) {
            let val = UInt32(bytes: self, fromIndex: idx).bigEndian
            result.append(val)
        }
        
        return result
    }
    
    // Big endian order
    func toUInt64Array() -> Array<UInt64> {
        if isEmpty {
            return []
        }
        
        var result = Array<UInt64>(reserveCapacity: 32)
        for idx in stride(from: startIndex, to: endIndex, by: 8) {
            let val = UInt64(bytes: self, fromIndex: idx).bigEndian
            result.append(val)
        }
        
        return result
    }
}

public protocol Updatable {
    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process.
    /// - parameter isLast: Indicate if given chunk is the last one. No more updates after this call.
    /// - returns: Processed data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool) throws -> Array<UInt8>
    /// Update given bytes in chunks.
    ///
    /// - Parameters:
    ///   - bytes: Bytes to process.
    ///   - isLast: Indicate if given chunk is the last one. No more updates after this call.
    ///   - output: Resulting bytes callback.
    /// - Returns: Processed data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool, output: (_ bytes: Array<UInt8>) -> Void) throws
    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - returns: Processed data.
    mutating func finish(withBytes bytes: ArraySlice<UInt8>) throws -> Array<UInt8>
    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - parameter output: Resulting data
    /// - returns: Processed data.
    mutating func finish(withBytes bytes: ArraySlice<UInt8>, output: (_ bytes: Array<UInt8>) -> Void) throws
}

extension Array {
    init(reserveCapacity: Int) {
        self = Array<Element>()
        self.reserveCapacity(reserveCapacity)
    }
    
    var slice: ArraySlice<Element> {
        return self[self.startIndex..<self.endIndex]
    }
}
extension Array {
    
    /// split in chunks with given chunk size
    @available(*, deprecated: 0.8.0, message: "")
    public func chunks(size chunksize: Int) -> Array<Array<Element>> {
        var words = Array<Array<Element>>()
        words.reserveCapacity(count / chunksize)
        for idx in stride(from: chunksize, through: count, by: chunksize) {
            words.append(Array(self[idx - chunksize..<idx])) // slow for large table
        }
        let remainder = suffix(count % chunksize)
        if !remainder.isEmpty {
            words.append(Array(remainder))
        }
        return words
    }
}
extension Array where Element == UInt8 {
    
    public init(hex: String) {
        self.init(reserveCapacity: hex.unicodeScalars.lazy.underestimatedCount)
        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
}

