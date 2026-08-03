import XCTest

/// Navigation and capture only — behaviour is asserted by `iBaseUITests`, not here.
///
/// Driven by `bundle exec fastlane ios screenshots`, which loops the devices and locales in
/// `fastlane/Snapfile` and pins the status bar to 9:41 before each run.
///
/// Every test is an independent launch. That costs seconds and buys determinism: no test inherits
/// scroll position, navigation depth, or a toggled switch from the one before it.
/// `@MainActor` because snapshot's `setupSnapshot`/`snapshot` helpers are main-actor isolated and
/// this project builds in Swift 6 language mode. XCTest already runs these on the main thread.
@MainActor
final class ScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false
  }

  // MARK: Screens

  func testScreenshot01Readout() throws {
    let app = self.launchApp()

    self.require(app.staticTexts["readoutValue"], describedAs: "the readout value")
    self.require(app.otherElements["bitFieldView"], describedAs: "the bit field")
    self.require(app.buttons["baseRow-16"], describedAs: "the hex row")

    self.capture("01Readout")
  }

  func testScreenshot02Entry() throws {
    let app = self.launchApp()

    self.require(app.staticTexts["readoutValue"], describedAs: "the readout value")
    self.tap(app.buttons["openEntryButton"], describedAs: "the enter-value button")
    self.require(app.buttons["keypadKey-7"], describedAs: "the keypad")

    // Hex, so the image shows live and dead keys together — the point of the screen.
    self.tap(app.buttons["entryBaseMenu"], describedAs: "the entry base menu")
    self.tapMenuOption(app.buttons["entryBaseOption-16"], describedAs: "base 16")
    self.tap(app.buttons["keypadKey-7"], describedAs: "digit 7")
    self.tap(app.buttons["keypadKey-E"], describedAs: "digit E")

    self.waitForLabel("= 126₁₀ so far", on: app.staticTexts["previewLabel"])

    self.capture("02Entry")
  }

  func testScreenshot03History() throws {
    let app = self.launchApp()

    self.require(app.staticTexts["readoutValue"], describedAs: "the readout value")
    self.tap(app.buttons["historyButton"], describedAs: "the history button")

    // Assert the seeded rows, so an empty list can never be captured and shipped.
    self.require(app.buttons["historyEntry-2026"], describedAs: "the 2026 history row")
    self.require(app.buttons["historyEntry-7E"], describedAs: "the 7E history row")

    self.capture("03History")
  }

  func testScreenshot04Settings() throws {
    let app = self.launchApp()

    self.require(app.staticTexts["readoutValue"], describedAs: "the readout value")
    self.tap(app.buttons["settingsButton"], describedAs: "the settings button")

    self.require(app.switches["baseVisibilityToggle-2"], describedAs: "the binary toggle")
    self.require(app.switches["baseVisibilityToggle-10"], describedAs: "the decimal toggle")

    self.capture("04Settings")
  }

  // MARK: Launching

  @discardableResult
  private func launchApp() -> XCUIApplication {
    let app = XCUIApplication()
    setupSnapshot(app)

    // The app requests no permissions today — no notifications, location, camera, photos, or ATT.
    // Registered anyway: the moment one is added, an unhandled system alert would sit over the UI
    // and quietly ruin every capture from that point on.
    self.addUIInterruptionMonitor(withDescription: "system dialog") { alert in
      for label in ["Allow", "Allow While Using App", "OK", "Continue"] where alert.buttons[label].exists {
        alert.buttons[label].tap()
        return true
      }
      return false
    }

    app.launch()
    self.app = app
    return app
  }

  // MARK: Readiness — never `sleep`

  /// Waits for existence *and* hittability. Existence alone is not enough: SwiftUI inserts elements
  /// into the tree before they are laid out and drawn, which is exactly how a capture ends up
  /// half-rendered on a CI runner, where everything is slower than a developer's machine.
  private func require(
    _ element: XCUIElement,
    describedAs description: String,
    timeout: TimeInterval = 30.0,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertTrue(
      element.waitForExistence(timeout: timeout),
      "\(description) never appeared — refusing to capture whatever happens to be on screen",
      file: file,
      line: line
    )

    let hittable = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isHittable == true"),
      object: element
    )

    guard XCTWaiter().wait(for: [hittable], timeout: timeout) == .completed else {
      return XCTFail("\(description) appeared but never became hittable", file: file, line: line)
    }
  }

  private func tap(
    _ element: XCUIElement,
    describedAs description: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    self.require(element, describedAs: description, file: file, line: line)
    element.tap()
  }

  /// A menu item is a different readiness problem from a screen element. The base menu lists all
  /// 35 entry bases, so an item can legitimately exist while sitting below the popover's fold and
  /// reporting `isHittable == false` until scrolled. XCUITest scrolls it into view as part of the
  /// tap, so existence is the correct signal here — requiring hittability would be wrong, not
  /// stricter.
  private func tapMenuOption(
    _ element: XCUIElement,
    describedAs description: String,
    timeout: TimeInterval = 30.0,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertTrue(
      element.waitForExistence(timeout: timeout),
      "\(description) never appeared in the menu",
      file: file,
      line: line
    )
    element.tap()
  }

  private func waitForLabel(
    _ label: String,
    on element: XCUIElement,
    timeout: TimeInterval = 15.0,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", label),
      object: element
    )

    guard XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed else {
      return XCTFail("expected label \"\(label)\", found \"\(element.label)\"", file: file, line: line)
    }
  }

  /// A raised keyboard silently changes the layout, so it must be down before any capture. iBase
  /// only raises one (history search, past ten entries) but this must not depend on that.
  private func dismissKeyboardIfPresent() {
    guard self.app.keyboards.count > 0 else { return }

    let done = self.app.keyboards.buttons["Done"]
    done.exists ? done.tap() : self.app.typeText("\n")

    let gone = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "count == 0"),
      object: self.app.keyboards
    )
    _ = XCTWaiter().wait(for: [gone], timeout: 5.0)
  }

  private func capture(_ name: String) {
    self.dismissKeyboardIfPresent()
    snapshot(name)
  }
}
