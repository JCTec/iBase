import XCTest
import SwiftData
@testable import iBase

/// The model is an immutable snapshot — these tests pin the `UInt64` ↔ `Int64` bridging and the
/// identity semantics the rest of the app relies on (docs/04 §3).
@MainActor
final class HistoryEntryTests: XCTestCase {

  func testValueBitPatternRoundTripsTheWholeUInt64Range() {
    let values: [UInt64] = [0, 1, 2026, UInt64(Int64.max), UInt64(Int64.max) + 1, .max]

    for value in values {
      let entry = HistoryEntry(value: value)

      XCTAssertEqual(entry.value, value, "bit-pattern bridging lost \(value)")
    }
  }

  func testValuesAboveInt64MaxAreStoredAsNegativeBitPatterns() {
    let entry = HistoryEntry(value: .max)

    XCTAssertEqual(entry.valueBitPattern, -1)
    XCTAssertEqual(entry.value, UInt64.max)
  }

  func testEnteredDigitsRenderInTheEnteredBase() {
    XCTAssertEqual(HistoryEntry(value: 126, enteredBase: 16).enteredDigits, "7E")
    XCTAssertEqual(HistoryEntry(value: 2026, enteredBase: 10).enteredDigits, "2026")
    XCTAssertEqual(HistoryEntry(value: 255, enteredBase: 2).enteredDigits, "11111111")
  }

  func testParameterlessInitUsesTheDefaults() {
    let entry = HistoryEntry()

    XCTAssertEqual(entry.value, 0)
    XCTAssertEqual(entry.enteredBase, HistoryEntry.defaultBase)
    XCTAssertEqual(HistoryEntry.defaultBase, 10)
  }

  /// Identity, never value, semantics — two entries holding the same number are still two entries.
  func testEqualityIsIdentityBased() {
    let first = HistoryEntry(value: 2026, enteredBase: 10)
    let second = HistoryEntry(value: 2026, enteredBase: 10)

    XCTAssertEqual(first, first)
    XCTAssertNotEqual(first, second)
    XCTAssertEqual(Set([first, second, first]).count, 2)
  }

  func testEntriesPersistAndFetchBack() throws {
    let container = try ModelContainer(
      for: HistoryEntry.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    container.mainContext.insert(HistoryEntry(value: .max, enteredBase: 36))
    try container.mainContext.save()

    let stored = try container.mainContext.fetch(FetchDescriptor<HistoryEntry>())

    XCTAssertEqual(stored.count, 1)
    XCTAssertEqual(stored.first?.value, UInt64.max)
    XCTAssertEqual(stored.first?.enteredDigits, "3W5E11264SGSF")
  }
}
