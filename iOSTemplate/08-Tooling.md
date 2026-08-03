# 08 — Tooling & Automation

## App Intents / Siri Shortcuts

Wire the primary action to the system. Declared in `MyAppApp.swift` alongside the entry point:

```swift
struct OpenMyAppIntent: AppIntent {
  static var title: LocalizedStringResource = "Open MyApp"
  static var description = IntentDescription("Open MyApp and start your primary action.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    return .result()
  }
}

struct MyAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenMyAppIntent(),
      phrases: [
        "Open \(.applicationName)",
        "Start with \(.applicationName)"
      ],
      shortTitle: "Open MyApp",
      systemImageName: "app.fill"
    )
  }
}
```

Grow beyond open-app (increment, log, query) when the app's primary action makes sense by voice.

## App Store screenshots — reproducible, never hand-made

Screenshots come from a command, not manual capture, so they regenerate whenever the UI changes.

**Layer 1 — capture (UI test):** an `AppStoreScreenshotUITests` case launches with `-ShowcaseData`, walks the marquee screens, and writes PNGs to `APPSTORE_SCREENSHOT_DIR` (env var, temp-dir fallback), also attaching them to the test report:

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

    XCTAssertTrue(self.app.staticTexts["MainTitle"].waitForExistence(timeout: 5.0))
    try self.captureScreenshot(named: "01-dashboard")
    // …navigate via accessibility identifiers, capture each marquee screen…
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

**Layer 2 — composition (script):** `Scripts/generate_appstore_assets.swift`, run from the repo root, resizes/frames captures into every required App Store dimension (e.g. iPhone 6.9" 1320×2868, iPhone 6.5" 1242×2688, iPad 13" 2064×2752) and writes them to `AppStoreAssets/` in per-device folders. Marketing text overlays live in the script so localized/styled variants regenerate too.

## Dependencies

Swift Package Manager only. Each package needs a one-line justification (e.g. ColorKit: hex parsing + WCAG contrast ratios, which UIKit lacks). If it can be written in under ~100 lines, write it.

## Project settings

- Universal iPhone + iPad from one codebase; recent iOS deployment target.
- Asset catalog: single-size AppIcon, `Colors/` folder with light/dark variants.
- Entitlements file present from day one (CloudKit-ready even before sync ships).
