import Foundation

/// Pure, stateless conversion logic shared by every screen (docs/04 §3b).
///
/// Every piece of base arithmetic in iBase lives here — no view does its own maths.
/// Bases 2–36 use the standard library's radix conversion; Base64 is `Foundation`.
/// Zero dependencies, by design (docs/01).
public enum Radix {

  // MARK: Bounds

  public static let minimumBase = 2
  public static let maximumBase = 36

  /// Base64 is not a positional base — it rides along as a special row (docs/00).
  /// The number is used purely as a stable row/identifier key: `baseRow-64`.
  public static let base64Base = 64

  /// Every base the keypad can type in.
  public static let entryBases: [Int] = Array(Radix.minimumBase...Radix.maximumBase)

  /// Every row the readout renders, in order: 2–36 then Base64 ("RADIX 2–64").
  public static let displayBases: [Int] = Radix.entryBases + [Radix.base64Base]

  /// Widths the bit field collapses to.
  public static let bitWidths = [16, 32, 64]

  private static let digitAlphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  private static let binaryGroupSize = 4

  // MARK: Formatting

  /// Uppercase digits for bases 2–36 (e.g. 2026 base 16 → "7EA").
  public static func string(from value: UInt64, base: Int) -> String {
    return String(value, radix: base, uppercase: true)
  }

  /// Big-endian bytes, leading zero bytes stripped: 2026 → 0x07EA → "B+o=". Zero → "AA==".
  public static func base64String(from value: UInt64) -> String {
    var bytes = withUnsafeBytes(of: value.bigEndian) { buffer in
      return Array(buffer)
    }

    while bytes.count > 1, bytes.first == 0 {
      bytes.removeFirst()
    }

    return Data(bytes).base64EncodedString()
  }

  /// Binary grouped into nibbles from the right, as the design renders it: 2026 → "111 1110 1010".
  public static func groupedBinaryString(from value: UInt64) -> String {
    let digits = Array(Radix.string(from: value, base: Radix.minimumBase))
    var groups: [String] = []
    var index = digits.count

    while index > 0 {
      let start = max(0, index - Radix.binaryGroupSize)
      groups.insert(String(digits[start..<index]), at: 0)
      index = start
    }

    return groups.joined(separator: " ")
  }

  /// What a readout row shows for a base: grouped binary, plain digits, or Base64.
  public static func displayString(from value: UInt64, base: Int) -> String {
    switch base {
      case Radix.base64Base:
        return Radix.base64String(from: value)
      case Radix.minimumBase:
        return Radix.groupedBinaryString(from: value)
      default:
        return Radix.string(from: value, base: base)
    }
  }

  /// The short instrument-panel label for a base: "BIN", "OCT", "DEC", "HEX", "B64", else "B\(base)".
  public static func label(for base: Int) -> String {
    switch base {
      case 2:
        return "BIN"
      case 8:
        return "OCT"
      case 10:
        return "DEC"
      case 16:
        return "HEX"
      case Radix.base64Base:
        return "B64"
      default:
        return "B\(base)"
    }
  }

  // MARK: Parsing

  /// Throws on illegal digits; nil-guards handled by the caller's keypad, so this backs paste/intents too.
  public static func value(from digits: String, base: Int) throws -> UInt64 {
    guard let value = UInt64(digits, radix: base) else {
      throw ParseError.invalidDigits(digits, base: base)
    }
    return value
  }

  // MARK: Keypad support

  /// The legal digit characters for a base, in keypad order: "0"…"9", "A"…"Z" prefix.
  public static func legalDigits(for base: Int) -> [Character] {
    guard base >= Radix.minimumBase, base <= Radix.maximumBase else {
      return []
    }
    return Array(Radix.digitAlphabet.prefix(base))
  }

  /// Every digit the keypad renders, legal or not — the grid never reflows (docs/06).
  public static var keypadDigits: [Character] {
    return Radix.digitAlphabet
  }

  // MARK: Bit field

  /// Smallest of 16/32/64 that contains the value's highest set bit (collapsing bit field).
  public static func displayBitWidth(for value: UInt64) -> Int {
    let significantBits = UInt64.bitWidth - value.leadingZeroBitCount

    for width in Radix.bitWidths where significantBits <= width {
      return width
    }

    return UInt64.bitWidth
  }

  // MARK: Errors

  public enum ParseError: LocalizedError, Equatable {
    case invalidDigits(String, base: Int)

    public var errorDescription: String? {
      switch self {
        case .invalidDigits(let digits, let base):
          return "\"\(digits)\" is not a valid base-\(base) value."
      }
    }
  }
}
