import XCTest

/// The one end-to-end journey, driven entirely through accessibility identifiers (docs/07).
///
/// `@MainActor` so the `waitForExpectations` helper from docs/07 satisfies Swift 6 strict
/// concurrency — XCTest already runs these on the main thread.
@MainActor
final class iBaseUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false
  }

  /// docs/07 sets `app.launchArguments` in `setUpWithError`. XCTest declares that hook nonisolated
  /// while `XCUIApplication` is main-actor isolated, so under Swift 6 the app is built here —
  /// inside the test body, which is on the main actor.
  private func launchApp() {
    let app = XCUIApplication()
    app.launchArguments = ["-UITesting"]

    self.app = app
    app.launch()
  }

  // MARK: The journey

  func testConvertCommitReloadAndDeleteJourney() throws {
    self.launchApp()

    // 1. Launch → the readout holds the default value; history is empty.
    let readout = self.app.staticTexts["readoutValue"]
    XCTAssertTrue(readout.waitForExistence(timeout: 5.0))
    self.wait(for: readout, toHaveLabel: "2026")

    self.app.buttons["historyButton"].tap()
    XCTAssertTrue(self.element("emptyHistoryView").waitForExistence(timeout: 5.0))

    // 2. Back to the readout → pick hex → open the keypad.
    self.popToReadout()
    XCTAssertTrue(readout.waitForExistence(timeout: 5.0))

    let hexRow = self.app.buttons["baseRow-16"]
    self.reveal(hexRow)
    hexRow.tap()
    self.wait(for: readout, toHaveLabel: "7EA") // 2026 in hex — the base switch landed

    let openEntryButton = self.app.buttons["openEntryButton"]
    self.reveal(openEntryButton)
    openEntryButton.tap()

    // 3. Radix awareness: E is alive in hex, dead-but-present in decimal.
    let keyE = self.app.buttons["keypadKey-E"]
    XCTAssertTrue(keyE.waitForExistence(timeout: 5.0))
    XCTAssertTrue(keyE.isEnabled, "E must be typeable in base 16")

    self.selectEntryBase(10)
    XCTAssertTrue(keyE.exists, "dead digits are dimmed, never hidden")
    XCTAssertFalse(keyE.isEnabled, "E must be dead in base 10")

    self.selectEntryBase(16)
    XCTAssertTrue(keyE.isEnabled)

    // 4. Type 7E → the live preview agrees with the parse.
    self.tapKey("7")
    self.tapKey("E")

    let previewLabel = self.app.staticTexts["previewLabel"]
    XCTAssertTrue(previewLabel.waitForExistence(timeout: 5.0))
    self.wait(for: previewLabel, toHaveLabel: "= 126₁₀ so far")

    // 5. Commit → the readout carries the value in every base at once.
    self.app.buttons["commitButton"].tap()

    XCTAssertTrue(readout.waitForExistence(timeout: 5.0))
    // The big readout renders in the *selected* base, which step 2 set to 16 — so the value 126
    // reads as "7E" there and as "126" on the decimal row. (Reading of docs/07 step 5, flagged.)
    self.wait(for: readout, toHaveLabel: "7E")

    let decimalRow = self.app.buttons["baseRow-10"]
    self.reveal(decimalRow)
    self.wait(for: decimalRow, toHaveValue: "126")

    let binaryRow = self.app.buttons["baseRow-2"]
    self.reveal(binaryRow)
    self.wait(for: binaryRow, toHaveValue: "111 1110")

    let bitField = self.app.otherElements["bitFieldView"]
    XCTAssertTrue(bitField.waitForExistence(timeout: 5.0))
    self.wait(for: bitField, toHaveValue: "6 of 16 bits set")

    // 6. History holds the commit; tapping it loads the value back into the readout.
    self.scrollToTop()
    self.app.buttons["historyButton"].tap()

    let historyEntry = self.app.buttons["historyEntry-7E"]
    XCTAssertTrue(historyEntry.waitForExistence(timeout: 5.0))
    historyEntry.tap()

    XCTAssertTrue(readout.waitForExistence(timeout: 5.0))
    self.wait(for: readout, toHaveLabel: "7E")

    // 7. Delete it → back to the empty state.
    self.scrollToTop()
    self.app.buttons["historyButton"].tap()

    let entryToDelete = self.app.buttons["historyEntry-7E"]
    XCTAssertTrue(entryToDelete.waitForExistence(timeout: 5.0))
    entryToDelete.swipeLeft()

    let deleteButton = self.app.buttons["deleteEntryButton-7E"].firstMatch
    XCTAssertTrue(deleteButton.waitForExistence(timeout: 5.0))
    deleteButton.tap()

    // The dialog renders a matching button per presentation anchor — take the live one.
    let confirmButton = self.app.buttons["confirmDeleteButton"].firstMatch
    XCTAssertTrue(confirmButton.waitForExistence(timeout: 5.0))
    confirmButton.tap()

    XCTAssertTrue(self.element("emptyHistoryView").waitForExistence(timeout: 5.0))
  }

  // MARK: Settings — which bases the readout shows

  func testSettingsControlsWhichBaseRowsAppear() throws {
    self.launchApp()

    XCTAssertTrue(self.app.staticTexts["readoutValue"].waitForExistence(timeout: 5.0))

    // A fresh device shows the default set and nothing else — no seeding, no first-run pass.
    XCTAssertTrue(self.app.buttons["baseRow-2"].exists)
    XCTAssertTrue(self.app.buttons["baseRow-8"].exists)
    XCTAssertTrue(self.app.buttons["baseRow-10"].exists)
    XCTAssertTrue(self.app.buttons["baseRow-16"].exists)
    XCTAssertTrue(self.app.buttons["baseRow-64"].exists)
    XCTAssertFalse(self.app.buttons["baseRow-3"].exists, "base 3 starts hidden")
    XCTAssertFalse(self.app.buttons["baseRow-36"].exists, "base 36 starts hidden")

    // Turn one on.
    self.openSettings()
    self.setBaseVisible(true, for: 36)
    self.popToReadout()

    XCTAssertTrue(self.app.buttons["baseRow-36"].waitForExistence(timeout: 5.0))

    // Turn a default one off.
    self.openSettings()
    self.setBaseVisible(false, for: 8)
    self.popToReadout()

    XCTAssertTrue(self.app.staticTexts["readoutValue"].waitForExistence(timeout: 5.0))
    XCTAssertFalse(self.app.buttons["baseRow-8"].exists, "base 8 was switched off")
    XCTAssertTrue(self.app.buttons["baseRow-36"].exists, "base 36 is still on")

    // Restoring puts the default set back exactly.
    self.openSettings()

    let restoreButton = self.app.buttons["restoreDefaultsButton"]
    XCTAssertTrue(restoreButton.waitForExistence(timeout: 5.0))
    restoreButton.tap()
    self.popToReadout()

    XCTAssertTrue(self.app.buttons["baseRow-8"].waitForExistence(timeout: 5.0))
    XCTAssertFalse(self.app.buttons["baseRow-36"].exists)
  }

  func testHidingEveryBaseShowsTheEmptyState() throws {
    self.launchApp()

    XCTAssertTrue(self.app.staticTexts["readoutValue"].waitForExistence(timeout: 5.0))

    self.openSettings()
    [2, 8, 10, 16, 64].forEach { base in
      self.setBaseVisible(false, for: base)
    }
    self.popToReadout()

    XCTAssertTrue(self.element("noVisibleBasesView").waitForExistence(timeout: 5.0))
    // The value itself never disappears — only the rows are filtered.
    XCTAssertTrue(self.app.staticTexts["readoutValue"].exists)
  }

  // MARK: Tapping the readout card starts an entry

  func testTappingTheInputCardOpensTheKeypad() throws {
    self.launchApp()

    let readout = self.app.staticTexts["readoutValue"]
    XCTAssertTrue(readout.waitForExistence(timeout: 5.0))

    readout.tap()

    XCTAssertTrue(
      self.app.buttons["keypadKey-7"].waitForExistence(timeout: 5.0),
      "tapping the card must do what ENTER VALUE does"
    )
  }

  // MARK: Launch performance

  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      let app = XCUIApplication()
      app.launchArguments = ["-UITesting"]
      app.launch()
    }
  }

  // MARK: Helpers

  /// `ContentUnavailableView` collapses to a static text, base rows to buttons — query by
  /// identifier across every element type so the test never encodes a rendering detail.
  private func element(_ identifier: String) -> XCUIElement {
    return self.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
  }

  private func wait(for element: XCUIElement, toHaveLabel label: String, timeout: TimeInterval = 3.0) {
    let predicate = NSPredicate(format: "label == %@", label)
    expectation(for: predicate, evaluatedWith: element)
    waitForExpectations(timeout: timeout)
  }

  private func wait(for element: XCUIElement, toHaveValue value: String, timeout: TimeInterval = 3.0) {
    let predicate = NSPredicate(format: "value == %@", value)
    expectation(for: predicate, evaluatedWith: element)
    waitForExpectations(timeout: timeout)
  }

  /// The readout is 36 rows deep on compact widths — bring the target into reach before tapping,
  /// scrolling toward it rather than in one fixed direction.
  private func reveal(_ element: XCUIElement, maximumSwipes: Int = 14) {
    XCTAssertTrue(element.waitForExistence(timeout: 5.0), "\(element) never appeared")

    var swipes = 0
    while !element.isHittable, swipes < maximumSwipes {
      if element.frame.midY > self.app.frame.midY {
        self.app.swipeUp()
      } else {
        self.app.swipeDown()
      }
      swipes += 1
    }

    XCTAssertTrue(element.isHittable, "could not scroll \(element) into view")
  }

  private func scrollToTop() {
    self.reveal(self.app.buttons["historyButton"])
  }

  private func tapKey(_ digit: String) {
    let key = self.app.buttons["keypadKey-\(digit)"]
    XCTAssertTrue(key.waitForExistence(timeout: 5.0))
    self.reveal(key)
    key.tap()
  }

  private func selectEntryBase(_ base: Int) {
    self.app.buttons["entryBaseMenu"].tap()

    let option = self.app.buttons["entryBaseOption-\(base)"]
    XCTAssertTrue(option.waitForExistence(timeout: 5.0))
    option.tap()
  }

  private func openSettings() {
    let settingsButton = self.app.buttons["settingsButton"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
    self.reveal(settingsButton)
    settingsButton.tap()
  }

  private func setBaseVisible(_ isVisible: Bool, for base: Int) {
    let toggle = self.app.switches["baseVisibilityToggle-\(base)"]

    // The settings list is lazy: a row 30 bases down does not merely sit off-screen, it does not
    // exist yet — so scroll it into being before asking anything about it.
    self.scrollIntoExistence(toggle)
    self.reveal(toggle)

    let isCurrentlyOn = (toggle.value as? String) == "1"
    guard isCurrentlyOn != isVisible else { return }

    toggle.tap()
  }

  private func scrollIntoExistence(_ element: XCUIElement, maximumSwipes: Int = 24) {
    guard !element.exists else { return }

    for _ in 0..<maximumSwipes where !element.exists {
      self.app.swipeUp()
    }

    // It may equally be above the current position, e.g. after walking down the list.
    for _ in 0..<maximumSwipes where !element.exists {
      self.app.swipeDown()
    }

    XCTAssertTrue(element.exists, "\(element) never materialised in the list")
  }

  private func popToReadout() {
    let backButton = self.app.navigationBars.buttons.firstMatch
    XCTAssertTrue(backButton.waitForExistence(timeout: 5.0))
    backButton.tap()
  }
}
