# 08 — Tooling & Automation

## App Intents / Siri Shortcuts

Per the brief (`00`), the primary action is **open the app** — open-app intent only, declared in `iBaseApp.swift` alongside the entry point:

```swift
struct OpeniBaseIntent: AppIntent {
  static var title: LocalizedStringResource = "Open iBase"
  static var description = IntentDescription("Open iBase and see the number in every base.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    return .result()
  }
}

struct iBaseShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpeniBaseIntent(),
      phrases: [
        "Open \(.applicationName)",
        "Convert a number with \(.applicationName)"
      ],
      shortTitle: "Open iBase",
      systemImageName: "number.square.fill"
    )
  }
}
```

Natural growth path (not now, recorded for later): a `ConvertNumberIntent` taking a value + base and returning the conversions as a snippet — the app's job makes sense by voice. Ship open-app first.

## App Store screenshots — reproducible, never hand-made

Screenshots come from a command, not manual capture, so they regenerate whenever the UI changes.

**Layer 1 — capture (UI test):** `AppStoreScreenshotUITests` launches with `-ShowcaseData` (readout at 2026, history seeded per `07`), walks the marquee screens, and writes PNGs to `APPSTORE_SCREENSHOT_DIR` (env var, temp-dir fallback), also attaching them to the test report:

```swift
final class AppStoreScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!
  private var screenshotDirectory: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false

    self.app = XCUIApplication()
    self.app.launchArguments = ["-ShowcaseData"]

    let directoryPath = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOT_DIR"]
      ?? NSTemporaryDirectory()
    self.screenshotDirectory = URL(fileURLWithPath: directoryPath, isDirectory: true)
  }

  func testCaptureAppStoreScreenshots() throws {
    self.app.launch()

    XCTAssertTrue(self.app.staticTexts["readoutValue"].waitForExistence(timeout: 5.0))
    try self.captureScreenshot(named: "01-readout")        // 2026 across every base + bit field

    self.app.buttons["openEntryButton"].tap()
    self.app.buttons["keypadKey-7"].tap()
    self.app.buttons["keypadKey-E"].tap()
    try self.captureScreenshot(named: "02-entry")          // 7E, "= 126₁₀ so far", dimmed dead keys

    self.app.buttons["backButton"].tap()
    self.app.buttons["historyButton"].tap()
    try self.captureScreenshot(named: "03-history")
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
```

**Layer 2 — composition (script):** `Scripts/generate_appstore_assets.swift`, run from the repo root, resizes/frames captures into every required App Store dimension (iPhone 6.9" 1320×2868, iPhone 6.5" 1242×2688, iPad 13" 2064×2752, plus Mac App Store 2880×1800) and writes them to `AppStoreAssets/` in per-device folders. Marketing text overlays ("The number is a readout, not a text field.") live in the script so localized/styled variants regenerate too.

## Dependencies

Swift Package Manager only; expected count **zero**. Base 2–36 is `String(_:radix:)`/`UInt64(_:radix:)`, Base64 is `Foundation`, and with the fixed palette there is no contrast-math dependency (ColorKit not needed — flagged difference from the template's example). If something is proposed, it needs a one-line justification; under ~100 lines, write it instead.

## Project settings

- SwiftUI multiplatform target: iPhone + iPad + Mac from one codebase; latest major OS deployment targets.
- Forced dark appearance (`.preferredColorScheme(.dark)`); Info.plist `UIUserInterfaceStyle` = `Dark` on iOS.
- Asset catalog: single-size AppIcon, `Colors/` per `05` (single dark appearance).
- Entitlements file present from day one (CloudKit-ready even before sync ships).
