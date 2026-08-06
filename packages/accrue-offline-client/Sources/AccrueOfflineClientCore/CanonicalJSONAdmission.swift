import Foundation

/// A deliberately small JSON scanner used before Foundation turns objects into maps.
/// It only admits well-formed JSON with unique object member names at every depth.
enum CanonicalJSONAdmission {
    static let maximumNestingDepth = 32

    static func validate(_ data: Data) throws {
        var scanner = Scanner(bytes: Array(data))
        try scanner.value(depth: 0)
        scanner.space()
        guard scanner.index == scanner.bytes.count else { throw Error.malformed }
    }

    enum Error: Swift.Error { case malformed, duplicateMember }

    private struct Scanner {
        let bytes: [UInt8]
        var index = 0

        mutating func space() { while index < bytes.count && [9, 10, 13, 32].contains(bytes[index]) { index += 1 } }
        mutating func value(depth: Int) throws {
            space(); guard index < bytes.count else { throw Error.malformed }
            switch bytes[index] {
            case 123: try object(depth: depth)
            case 91: try array(depth: depth)
            case 34: _ = try string()
            case 45, 48...57: try number()
            default:
                guard consume("true") || consume("false") || consume("null") else { throw Error.malformed }
            }
        }
        mutating func object(depth: Int) throws {
            guard depth < CanonicalJSONAdmission.maximumNestingDepth else { throw Error.malformed }
            index += 1; space(); if take(125) { return }; var names = Set<String>()
            while true {
                space(); let name = try string()
                guard names.insert(name).inserted else { throw Error.duplicateMember }
                space(); guard take(58) else { throw Error.malformed }; try value(depth: depth + 1); space()
                if take(125) { return }; guard take(44) else { throw Error.malformed }
            }
        }
        mutating func array(depth: Int) throws {
            guard depth < CanonicalJSONAdmission.maximumNestingDepth else { throw Error.malformed }
            index += 1; space(); if take(93) { return }
            while true { try value(depth: depth + 1); space(); if take(93) { return }; guard take(44) else { throw Error.malformed } }
        }
        mutating func string() throws -> String {
            guard take(34) else { throw Error.malformed }; var value = ""
            while index < bytes.count {
                let byte = bytes[index]; index += 1
                if byte == 34 { return value }
                guard byte >= 32 else { throw Error.malformed }
                if byte == 92 {
                    guard index < bytes.count else { throw Error.malformed }; let escaped = bytes[index]; index += 1
                    switch escaped {
                    case 34, 92, 47: value.unicodeScalars.append(UnicodeScalar(escaped))
                    case 98: value.unicodeScalars.append("\u{08}")
                    case 102: value.unicodeScalars.append("\u{0C}")
                    case 110: value.append("\n")
                    case 114: value.append("\r")
                    case 116: value.append("\t")
                    case 117:
                        guard index + 4 <= bytes.count, let scalar = UInt32(String(bytes: bytes[index..<(index + 4)], encoding: .utf8)!, radix: 16), let unicode = UnicodeScalar(scalar) else { throw Error.malformed }
                        index += 4; value.unicodeScalars.append(unicode)
                    default: throw Error.malformed
                    }
                } else { value.append(Character(UnicodeScalar(byte))) }
            }
            throw Error.malformed
        }
        mutating func number() throws {
            if take(45) {}; guard index < bytes.count else { throw Error.malformed }
            if take(48) {} else { try digits() }
            if take(46) { try digits() }; if take(69) || take(101) { _ = take(43) || take(45); try digits() }
        }
        mutating func digits() throws { let start = index; while index < bytes.count && bytes[index] >= 48 && bytes[index] <= 57 { index += 1 }; guard index > start else { throw Error.malformed } }
        mutating func take(_ byte: UInt8) -> Bool { guard index < bytes.count && bytes[index] == byte else { return false }; index += 1; return true }
        mutating func consume(_ value: String) -> Bool { let value = Array(value.utf8); guard bytes.dropFirst(index).starts(with: value) else { return false }; index += value.count; return true }
    }
}
