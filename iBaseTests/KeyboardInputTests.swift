import XCTest
@testable import iBase

/// Hardware-keyboard entry runs the *same* validation as the on-screen keypad. XCUITest cannot
/// drive a real keyboard on the simulator, so the policy is pinned here instead — on every
/// destination, including macOS where the feature actually matters.
@MainActor
final class KeyboardInputTests: XCTestCase {

  private func makeViewModel(base: Int, digits: String = "") -> EntryView.ViewModel {
    let viewModel = EntryView.ViewModel(base: base)
    viewModel.digits = digits
    return viewModel
  }

  // MARK: Digits legal in the current base

  func testTypingADigitLegalInTheBaseAppendsIt() {
    let viewModel = self.makeViewModel(base: 16)

    XCTAssertEqual(viewModel.command(for: .character("7")), .append("7"))
    XCTAssertEqual(viewModel.command(for: .character("E")), .append("E"))
  }

  func testTypingLowercaseFoldsToTheUppercaseAlphabet() {
    let viewModel = self.makeViewModel(base: 16)

    XCTAssertEqual(viewModel.command(for: .character("e")), .append("E"))
    XCTAssertEqual(viewModel.command(for: .character("f")), .append("F"))
  }

  func testTypingTheWholeAlphabetWorksInBase36() {
    let viewModel = self.makeViewModel(base: 36)

    XCTAssertEqual(viewModel.command(for: .character("z")), .append("Z"))
    XCTAssertEqual(viewModel.command(for: .character("0")), .append("0"))
  }

  // MARK: Digits illegal in the current base

  func testTypingADigitIllegalInTheBaseIsIgnored() {
    let decimal = self.makeViewModel(base: 10)

    // The keypad dims E in base 10; the keyboard must be exactly as dead.
    XCTAssertEqual(decimal.command(for: .character("E")), .ignore)
    XCTAssertEqual(decimal.command(for: .character("e")), .ignore)

    let binary = self.makeViewModel(base: 2)

    XCTAssertEqual(binary.command(for: .character("1")), .append("1"))
    XCTAssertEqual(binary.command(for: .character("2")), .ignore)
  }

  func testTypingANonDigitCharacterIsIgnored() {
    let viewModel = self.makeViewModel(base: 16)

    XCTAssertEqual(viewModel.command(for: .character("-")), .ignore)
    XCTAssertEqual(viewModel.command(for: .character(" ")), .ignore)
    XCTAssertEqual(viewModel.command(for: .character("€")), .ignore)
  }

  func testKeyboardAndKeypadAgreeOnLegalityForEveryBaseAndDigit() {
    for base in Radix.entryBases {
      let viewModel = self.makeViewModel(base: base)

      for digit in Radix.keypadDigits {
        let isTypeable = viewModel.command(for: .character(digit)) == .append(digit)

        XCTAssertEqual(
          isTypeable,
          viewModel.isLegal(digit),
          "base \(base) disagrees about \(digit): keypad says \(viewModel.isLegal(digit))"
        )
      }
    }
  }

  // MARK: Overflow

  func testTypingPastUInt64MaxIsIgnored() {
    let viewModel = self.makeViewModel(base: 10, digits: String(UInt64.max))

    XCTAssertEqual(viewModel.command(for: .character("0")), .ignore)
  }

  func testTypingTheDigitThatExactlyReachesUInt64MaxIsAllowed() {
    let maximumDigits = Radix.string(from: .max, base: 16)
    let viewModel = self.makeViewModel(base: 16, digits: String(maximumDigits.dropLast()))

    XCTAssertEqual(viewModel.command(for: .character("f")), .append("F"))
  }

  // MARK: Editing keys

  func testDeleteRemovesADigitAndNoOpsWhenEmpty() {
    XCTAssertEqual(self.makeViewModel(base: 16, digits: "7E").command(for: .delete), .delete)
    XCTAssertEqual(self.makeViewModel(base: 16).command(for: .delete), .ignore)
  }

  func testReturnCommitsOnlyWhenThereIsSomethingToCommit() {
    XCTAssertEqual(self.makeViewModel(base: 16, digits: "7E").command(for: .submit), .commit)
    XCTAssertEqual(self.makeViewModel(base: 16).command(for: .submit), .ignore)
  }

  func testReturnAgreesWithTheCommitButton() {
    let viewModel = self.makeViewModel(base: 16)

    XCTAssertFalse(viewModel.canCommit)
    XCTAssertEqual(viewModel.command(for: .submit), .ignore)

    viewModel.append("7")

    XCTAssertTrue(viewModel.canCommit)
    XCTAssertEqual(viewModel.command(for: .submit), .commit)
  }

  func testEscapeCancelsWhetherOrNotAnythingIsTyped() {
    XCTAssertEqual(self.makeViewModel(base: 16, digits: "7E").command(for: .cancel), .cancel)
    XCTAssertEqual(self.makeViewModel(base: 16).command(for: .cancel), .cancel)
  }

  // MARK: Base switching

  func testSwitchingBaseChangesWhatTheKeyboardAccepts() {
    let viewModel = self.makeViewModel(base: 16)

    XCTAssertEqual(viewModel.command(for: .character("e")), .append("E"))

    viewModel.base = 10

    XCTAssertEqual(viewModel.command(for: .character("e")), .ignore)
  }

  // MARK: Typing a whole value

  func testTypingSevenEInHexReachesOneHundredAndTwentySix() {
    let viewModel = self.makeViewModel(base: 16)

    for character in "7e" {
      guard case .append(let digit) = viewModel.command(for: .character(character)) else {
        return XCTFail("\(character) should be typeable in base 16")
      }
      viewModel.append(digit)
    }

    XCTAssertEqual(viewModel.digits, "7E")
    XCTAssertEqual(viewModel.previewValue, 126)
  }
}
