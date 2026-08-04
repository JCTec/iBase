import XCTest
import SwiftData
@testable import iBase

/// The guarded input rules: digit legality per base, 64-bit overflow, commit-to-history (docs/04 §4).
@MainActor
final class EntryViewModelTests: XCTestCase {

  private func makeInMemoryContainer() throws -> ModelContainer {
    return try ModelContainer(
      for: HistoryEntry.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
  }

  // MARK: Append guards

  func testAppendAcceptsDigitsLegalInCurrentBase() {
    let viewModel = EntryView.ViewModel(base: 16)

    viewModel.append("7")
    viewModel.append("E")

    XCTAssertEqual(viewModel.digits, "7E")
  }

  func testAppendIgnoresDigitsIllegalInCurrentBase() {
    let viewModel = EntryView.ViewModel(base: 2)

    viewModel.append("1")
    viewModel.append("2") // dead in base 2
    viewModel.append("F") // dead in base 2

    XCTAssertEqual(viewModel.digits, "1")
  }

  func testAppendIgnoresOverflowPastUInt64Max() {
    let viewModel = EntryView.ViewModel(base: 10)
    viewModel.digits = String(UInt64.max)

    viewModel.append("0")

    XCTAssertEqual(viewModel.digits, String(UInt64.max))
  }

  func testAppendAcceptsTheFinalDigitThatExactlyReachesUInt64Max() {
    let maximumDigits = Radix.string(from: .max, base: 16)
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.digits = String(maximumDigits.dropLast())

    viewModel.append(try! XCTUnwrap(maximumDigits.last))

    XCTAssertEqual(viewModel.digits, maximumDigits)
    XCTAssertEqual(viewModel.previewValue, UInt64.max)
  }

  func testAppendIsLegalAcrossTheWholeAlphabetInBase36() {
    let viewModel = EntryView.ViewModel(base: 36)

    XCTAssertTrue(viewModel.isLegal("0"))
    XCTAssertTrue(viewModel.isLegal("Z"))
    XCTAssertFalse(viewModel.isLegal("-"))
  }

  // MARK: Delete guards

  func testDeleteLastDigitNoOpsWhenEmpty() {
    let viewModel = EntryView.ViewModel(base: 10)

    viewModel.deleteLastDigit()

    XCTAssertEqual(viewModel.digits, "")
    XCTAssertFalse(viewModel.canCommit)
  }

  func testDeleteLastDigitRemovesOneDigit() {
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.digits = "7E"

    viewModel.deleteLastDigit()

    XCTAssertEqual(viewModel.digits, "7")
  }

  // MARK: Preview and commit agreement

  func testCanCommitAndPreviewValueDeriveFromTheSameParse() {
    let viewModel = EntryView.ViewModel(base: 16)

    XCTAssertFalse(viewModel.canCommit)
    XCTAssertNil(viewModel.previewValue)

    viewModel.append("7")
    viewModel.append("E")

    XCTAssertTrue(viewModel.canCommit)
    XCTAssertEqual(viewModel.previewValue, 126)
  }

  func testPreviewValueMatchesRadixForEveryReachableState() {
    let viewModel = EntryView.ViewModel(base: 8)

    "3752".forEach { digit in
      viewModel.append(digit)
      XCTAssertEqual(viewModel.previewValue, try? Radix.value(from: viewModel.digits, base: 8))
    }

    XCTAssertEqual(viewModel.previewValue, 2026)
  }

  // MARK: Base switching

  func testBaseSwitchingReEvaluatesLegality() {
    let viewModel = EntryView.ViewModel(base: 16)

    XCTAssertTrue(viewModel.isLegal("E"))

    viewModel.base = 10

    XCTAssertFalse(viewModel.isLegal("E"))

    viewModel.base = 16

    XCTAssertTrue(viewModel.isLegal("E"))
  }

  func testBaseSwitchingRereadsAlreadyTypedDigits() {
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.append("1")
    viewModel.append("0")

    XCTAssertEqual(viewModel.previewValue, 16)

    viewModel.base = 2

    XCTAssertEqual(viewModel.previewValue, 2)
  }

  // MARK: Persistence orchestration

  func testCommitInsertsHistoryEntry() throws {
    let container = try ModelContainer(
      for: HistoryEntry.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.append("7")
    viewModel.append("E")

    let entry = try viewModel.commit(in: container.mainContext)

    XCTAssertEqual(entry.value, 126)
    XCTAssertEqual(entry.enteredBase, 16)
  }

  func testCommitPersistsTheEntryIntoTheStore() throws {
    let container = try self.makeInMemoryContainer()
    let viewModel = EntryView.ViewModel(base: 10)
    viewModel.append("2")
    viewModel.append("0")
    viewModel.append("2")
    viewModel.append("6")

    try viewModel.commit(in: container.mainContext)

    let stored = try container.mainContext.fetch(FetchDescriptor<HistoryEntry>())

    XCTAssertEqual(stored.count, 1)
    XCTAssertEqual(stored.first?.value, 2026)
    XCTAssertEqual(stored.first?.enteredDigits, "2026")
  }

  func testCommitRoundTripsUInt64MaxThroughTheInt64BitPattern() throws {
    let container = try self.makeInMemoryContainer()
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.digits = Radix.string(from: .max, base: 16)

    let entry = try viewModel.commit(in: container.mainContext)

    XCTAssertEqual(entry.value, UInt64.max)
    XCTAssertEqual(entry.valueBitPattern, -1) // the whole point of the bridging

    let stored = try container.mainContext.fetch(FetchDescriptor<HistoryEntry>())

    XCTAssertEqual(stored.first?.value, UInt64.max)
  }

  func testCommitThrowsWhenThereIsNothingTyped() throws {
    let container = try self.makeInMemoryContainer()
    let viewModel = EntryView.ViewModel(base: 10)

    XCTAssertThrowsError(try viewModel.commit(in: container.mainContext)) { error in
      XCTAssertEqual(error as? Radix.ParseError, .invalidDigits("", base: 10))
    }

    XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<HistoryEntry>()).count, 0)
  }

  // MARK: Input errors

  /// Expectations are resolved through the String Catalog rather than spelled out in English, so
  /// the suite passes in every language the app ships. What is pinned is that each case reaches its
  /// own catalog key, and that the offending digit is substituted into the format.
  func testInputErrorsDescribeThemselves() {
    XCTAssertEqual(
      EntryView.InputError.illegalDigit("F").errorDescription,
      String(format: String(localized: "%1$@ is not a digit in this base.", bundle: .main), "F")
    )
    XCTAssertEqual(
      EntryView.InputError.overflow.errorDescription,
      String(localized: "Value exceeds the 64-bit maximum.", bundle: .main)
    )
    XCTAssertTrue(
      EntryView.InputError.illegalDigit("F").errorDescription?.contains("F") == true,
      "the digit that was rejected must survive into the message"
    )
  }
}
