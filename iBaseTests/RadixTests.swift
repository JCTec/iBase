import XCTest
@testable import iBase

/// `Radix` is the app's real business logic — every screen renders what it returns (docs/07).
@MainActor
final class RadixTests: XCTestCase {

  /// Values chosen to stress every boundary the app can hit.
  private let sampleValues: [UInt64] = [
    0,
    1,
    2,
    35,
    36,
    126,
    255,
    256,
    2026,
    65535,
    65536,
    UInt64(UInt32.max),
    UInt64(UInt32.max) + 1,
    UInt64.max
  ]

  // MARK: Round trips

  func testStringAndValueRoundTripForEveryBase() throws {
    for base in Radix.minimumBase...Radix.maximumBase {
      for value in self.sampleValues {
        let digits = Radix.string(from: value, base: base)
        let parsed = try Radix.value(from: digits, base: base)

        XCTAssertEqual(parsed, value, "base \(base) round-trip failed for \(value) (\"\(digits)\")")
      }
    }
  }

  func testZeroRoundTripsAsASingleZeroDigitInEveryBase() throws {
    for base in Radix.minimumBase...Radix.maximumBase {
      XCTAssertEqual(Radix.string(from: 0, base: base), "0")
      XCTAssertEqual(try Radix.value(from: "0", base: base), 0)
    }
  }

  func testUInt64MaxRoundTripsInEveryBase() throws {
    for base in Radix.minimumBase...Radix.maximumBase {
      let digits = Radix.string(from: .max, base: base)

      XCTAssertEqual(try Radix.value(from: digits, base: base), UInt64.max)
    }
  }

  func testUInt64MaxRendersItsWidestAndNarrowestForms() {
    XCTAssertEqual(Radix.string(from: .max, base: 2).count, 64)
    XCTAssertEqual(Radix.string(from: .max, base: 16), "FFFFFFFFFFFFFFFF")
    XCTAssertEqual(Radix.string(from: .max, base: 36), "3W5E11264SGSF")
  }

  // MARK: Design fixtures

  func testDesignReferenceValueRendersTheDesignsStrings() {
    let value: UInt64 = 2026

    XCTAssertEqual(Radix.string(from: value, base: 2), "11111101010")
    XCTAssertEqual(Radix.string(from: value, base: 8), "3752")
    XCTAssertEqual(Radix.string(from: value, base: 16), "7EA")
    XCTAssertEqual(Radix.string(from: value, base: 10), "2026")
  }

  func testTheDesignsHexEntryIsOneHundredAndTwentySix() throws {
    XCTAssertEqual(Radix.string(from: 126, base: 16), "7E")
    XCTAssertEqual(try Radix.value(from: "7E", base: 16), 126)
  }

  func testDigitsAreUppercased() {
    XCTAssertEqual(Radix.string(from: 2748, base: 16), "ABC")
    XCTAssertEqual(Radix.string(from: 35, base: 36), "Z")
  }

  func testGroupedBinaryMatchesTheDesignsNibbles() {
    XCTAssertEqual(Radix.groupedBinaryString(from: 2026), "111 1110 1010")
    XCTAssertEqual(Radix.groupedBinaryString(from: 126), "111 1110")
    XCTAssertEqual(Radix.groupedBinaryString(from: 0), "0")
    XCTAssertEqual(Radix.groupedBinaryString(from: 255), "1111 1111")
  }

  // MARK: Base64

  func testBase64StripsLeadingZeroBytes() {
    // 2026 is 0x00000000000007EA — only the two significant bytes are encoded.
    XCTAssertEqual(Radix.base64String(from: 2026), "B+o=")
    XCTAssertEqual(Radix.base64String(from: 255), "/w==")
    XCTAssertEqual(Radix.base64String(from: 256), "AQA=")
  }

  func testBase64OfZeroKeepsOneByte() {
    XCTAssertEqual(Radix.base64String(from: 0), "AA==")
  }

  func testBase64OfUInt64MaxEncodesAllEightBytes() {
    let encoded = Radix.base64String(from: .max)

    XCTAssertEqual(encoded, "//////////8=")
    XCTAssertEqual(Data(base64Encoded: encoded)?.count, 8)
  }

  func testBase64BytesAreBigEndian() throws {
    let decoded = try XCTUnwrap(Data(base64Encoded: Radix.base64String(from: 2026)))

    XCTAssertEqual(Array(decoded), [0x07, 0xEA])
  }

  // MARK: Legal digits

  func testLegalDigitCountsMatchTheBase() {
    XCTAssertEqual(Radix.legalDigits(for: 2).count, 2)
    XCTAssertEqual(Radix.legalDigits(for: 8).count, 8)
    XCTAssertEqual(Radix.legalDigits(for: 10).count, 10)
    XCTAssertEqual(Radix.legalDigits(for: 16).count, 16)
    XCTAssertEqual(Radix.legalDigits(for: 36).count, 36)
  }

  func testLegalDigitsAreInKeypadOrder() {
    XCTAssertEqual(Radix.legalDigits(for: 2), ["0", "1"])
    XCTAssertEqual(String(Radix.legalDigits(for: 16)), "0123456789ABCDEF")
    XCTAssertEqual(Radix.legalDigits(for: 36).last, "Z")
  }

  func testLegalDigitsAreEmptyOutsideTheSupportedRange() {
    XCTAssertTrue(Radix.legalDigits(for: Radix.minimumBase - 1).isEmpty)
    XCTAssertTrue(Radix.legalDigits(for: Radix.maximumBase + 1).isEmpty)
    XCTAssertTrue(Radix.legalDigits(for: Radix.base64Base).isEmpty)
  }

  func testKeypadAlwaysRendersThirtySixDigits() {
    // The grid never reflows when the base changes (docs/06).
    XCTAssertEqual(Radix.keypadDigits.count, 36)
  }

  // MARK: Bit width

  func testDisplayBitWidthCollapsesToSixteenForSmallValues() {
    XCTAssertEqual(Radix.displayBitWidth(for: 0), 16)
    XCTAssertEqual(Radix.displayBitWidth(for: 2026), 16)
    XCTAssertEqual(Radix.displayBitWidth(for: 65535), 16)
  }

  func testBitWidthGrowsAt65536() {
    XCTAssertEqual(Radix.displayBitWidth(for: 65535), 16)
    XCTAssertEqual(Radix.displayBitWidth(for: 65536), 32)
  }

  func testBitWidthGrowsPastUInt32Max() {
    XCTAssertEqual(Radix.displayBitWidth(for: UInt64(UInt32.max)), 32)
    XCTAssertEqual(Radix.displayBitWidth(for: UInt64(UInt32.max) + 1), 64)
    XCTAssertEqual(Radix.displayBitWidth(for: .max), 64)
  }

  // MARK: Parse errors

  func testValueThrowsOnDigitsIllegalInTheBase() {
    XCTAssertThrowsError(try Radix.value(from: "2", base: 2)) { error in
      XCTAssertEqual(error as? Radix.ParseError, .invalidDigits("2", base: 2))
    }

    XCTAssertThrowsError(try Radix.value(from: "G", base: 16)) { error in
      XCTAssertEqual(error as? Radix.ParseError, .invalidDigits("G", base: 16))
    }
  }

  func testValueThrowsOnOverflowPastUInt64Max() {
    let justPastMaximum = "18446744073709551616" // UInt64.max + 1

    XCTAssertThrowsError(try Radix.value(from: justPastMaximum, base: 10)) { error in
      XCTAssertEqual(error as? Radix.ParseError, .invalidDigits(justPastMaximum, base: 10))
    }
  }

  func testValueThrowsOnEmptyDigits() {
    XCTAssertThrowsError(try Radix.value(from: "", base: 10))
  }

  /// Resolved through the String Catalog, not hard-coded in English — see
  /// `EntryViewModelTests.testInputErrorsDescribeThemselves`.
  func testParseErrorCarriesAReadableDescription() {
    let error = Radix.ParseError.invalidDigits("G", base: 16)

    XCTAssertEqual(
      error.errorDescription,
      String(format: String(localized: "\"%1$@\" is not a valid base-%2$lld value.", bundle: .main), "G", 16)
    )
    XCTAssertTrue(error.errorDescription?.contains("G") == true)
    XCTAssertTrue(error.errorDescription?.contains("16") == true)
  }

  // MARK: Row presentation

  func testDisplayStringGroupsBinaryAndDelegatesBase64() {
    XCTAssertEqual(Radix.displayString(from: 2026, base: 2), "111 1110 1010")
    XCTAssertEqual(Radix.displayString(from: 2026, base: 16), "7EA")
    XCTAssertEqual(Radix.displayString(from: 2026, base: Radix.base64Base), "B+o=")
  }

  func testLabelsReadAsInstrumentPanelAbbreviations() {
    XCTAssertEqual(Radix.label(for: 2), "BIN")
    XCTAssertEqual(Radix.label(for: 8), "OCT")
    XCTAssertEqual(Radix.label(for: 10), "DEC")
    XCTAssertEqual(Radix.label(for: 16), "HEX")
    XCTAssertEqual(Radix.label(for: 36), "B36")
    XCTAssertEqual(Radix.label(for: Radix.base64Base), "B64")
  }

  func testDisplayBasesCoverTwoThroughThirtySixPlusBase64() {
    XCTAssertEqual(Radix.displayBases.first, 2)
    XCTAssertEqual(Radix.displayBases.last, Radix.base64Base)
    XCTAssertEqual(Radix.displayBases.count, 36) // 35 positional bases + Base64
    XCTAssertEqual(Radix.entryBases.count, 35)
  }
}
