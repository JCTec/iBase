import XCTest

/// Layer 1 of the screenshot pipeline: capture. Screenshots come from a command, never by hand,
/// so they regenerate whenever the UI changes (docs/08).
@MainActor
final class AppStoreScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!

  /// `APPSTORE_SCREENSHOT_DIR` with a temp-dir fallback (docs/08).
  private var screenshotDirectory: URL {
    let directoryPath = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOT_DIR"]
      ?? NSTemporaryDirectory()
    return URL(fileURLWithPath: directoryPath, isDirectory: true)
  }

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false
  }

  func testCaptureAppStoreScreenshots() throws {
    self.launchApp()

    XCTAssertTrue(self.app.staticTexts["readoutValue"].waitForExistence(timeout: 5.0))
    self.settle()
    try self.captureScreenshot(named: "01-readout")        // 2026 across every base + bit field

    let openEntryButton = self.app.buttons["openEntryButton"]
    XCTAssertTrue(openEntryButton.waitForExistence(timeout: 5.0))
    openEntryButton.tap()

    XCTAssertTrue(self.app.buttons["keypadKey-7"].waitForExistence(timeout: 5.0))

    // Flagged addition to the docs/08 script: showcase data opens at base 10, where E is dead — so
    // the literal script types "7" and captures "= 7₁₀ so far", not the "7E" frame the doc's own
    // comment describes. Selecting hex first is what makes the capture match its caption.
    self.selectEntryBase(16)

    self.app.buttons["keypadKey-7"].tap()
    self.app.buttons["keypadKey-E"].tap()
    self.settle()
    try self.captureScreenshot(named: "02-entry")          // 7E, "= 126₁₀ so far", dimmed dead keys

    self.app.buttons["backButton"].tap()

    let historyButton = self.app.buttons["historyButton"]
    XCTAssertTrue(historyButton.waitForExistence(timeout: 5.0))
    historyButton.tap()

    XCTAssertTrue(self.app.buttons["historyEntry-2026"].waitForExistence(timeout: 5.0))
    self.settle()
    try self.captureScreenshot(named: "03-history")
  }

  /// docs/08 builds the app in `setUpWithError`. XCTest declares that hook nonisolated while
  /// `XCUIApplication` is main-actor isolated, so under Swift 6 the app is built here instead —
  /// inside the test body, which is on the main actor.
  private func launchApp() {
    let app = XCUIApplication()
    app.launchArguments = ["-ShowcaseData"]

    self.app = app
    app.launch()
  }

  /// Numeric content transitions animate on every keystroke and base change — let them land so the
  /// marketing capture is sharp rather than caught mid-morph.
  private func settle(for duration: TimeInterval = 0.8) {
    Thread.sleep(forTimeInterval: duration)
  }

  private func selectEntryBase(_ base: Int) {
    self.app.buttons["entryBaseMenu"].tap()

    let option = self.app.buttons["entryBaseOption-\(base)"]
    XCTAssertTrue(option.waitForExistence(timeout: 5.0))
    option.tap()
  }

  private func captureScreenshot(named name: String) throws {
    try FileManager.default.createDirectory(
      at: self.screenshotDirectory,
      withIntermediateDirectories: true
    )

    let screenshot = XCUIScreen.main.screenshot()
    let outputURL = self.screenshotDirectory.appendingPathComponent("\(name).png")
    try screenshot.pngRepresentation.write(to: outputURL, options: .atomic)

    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    self.add(attachment)
  }
}
