---
description: Implement the complete iBase app from docs/ — sources, tests, UI tests, screenshots, and GitHub Actions CI
---

# Implement iBase

Build the entire iBase app exactly as specified in `docs/` (00–09). Those files are the contract — read ALL of them first, in order. Where this command and the docs conflict, the docs win; flag the conflict, never silently drop a rule.

## Fixed decisions (do not re-ask)

- Project generation: **XcodeGen** — `project.yml` committed, `.xcodeproj` gitignored, regenerated locally and in CI.
- Bundle IDs: `com.JCTechnologies.iBase` (+ `.tests` / `.uitests`). Marketing version **2.0.0**, build 1.
- Platforms: SwiftUI multiplatform — iPhone, iPad, macOS. Latest major OS deployment targets. Dark-only.
- CI: GitHub Actions, build + unit tests + UI tests on **iPhone sim, iPad sim, and macOS**. No signing/TestFlight (CI-only scope).
- Dependencies: zero. SPM only if something proves impossible in-platform (justify inline, per docs/01).

## Phase 1 — Project skeleton

1. `project.yml` (XcodeGen): targets `iBase` (iOS + macOS), `iBaseTests`, `iBaseUITests`; deployment targets; `-UITesting`/`-ShowcaseData` scheme launch args on a `iBase-UITests` scheme variant if needed; Info.plist with `UIUserInterfaceStyle: Dark`; entitlements file (empty, CloudKit-ready later).
2. `.gitignore` (Xcode/SPM standard + `*.xcodeproj`, `AppStoreAssets/`), `LaunchScreen.storyboard`, asset catalog with AppIcon placeholder and the five colors from docs/05 (`background #0B0B0C`, `panel #131316`, `text #F2F2F0`, `accent #7ED321`, `dimmed` = text at 0.40) — single appearance.
3. Verify: `xcodegen generate` succeeds and `xcodebuild -list` shows all targets/schemes.

## Phase 2 — Sources (follow docs/02 layout, docs/03 style to the letter)

1. `Utilities/`: `Spacing.swift`, `Borders.swift`, `IconSize.swift` copied verbatim from docs/05; `Radix.swift` fully implemented per docs/04 §3b (bases 2–36 uppercase, Base64 big-endian stripped-leading-zero-bytes — fixtures: 2026→`B+o=`, 0→`AA==`; `legalDigits(for:)`; `displayBitWidth(for:)` 16/32/64).
2. `HistoryEntry.swift` per docs/04 §3 (Int64 bitPattern storage, `@Transient` UInt64, identity Hashable, CloudKit-ready defaults).
3. `iBaseApp.swift` + `iBaseNavigationView.swift` per docs/04 §1–2, including `OpeniBaseIntent`/`iBaseShortcuts` from docs/08.
4. Features per docs/06: `ReadoutView` (+BitFieldView, +BaseRowView, +PreviewContainer), `EntryView` (+KeypadView, ViewModel in-file per docs/04 §4), `HistoryView` (+PreviewContainer). Every accessibility identifier named in docs/06–07 must exist exactly (`openEntryButton`, `commitButton`, `backButton`, `historyButton`, `keypadKey-\(digit)`, `baseRow-\(base)`, `historyEntry-…`, `readoutValue`, `emptyHistoryView`, `noSearchResultsView`).
5. Haptics behind a small wrapper that no-ops on macOS (docs/06). `#Preview` on every feature view with the edge-case seeds from docs/07.
6. Gate: `xcodebuild build` clean for an iOS simulator destination AND `-destination 'platform=macOS'`. Fix all warnings.

## Phase 3 — Unit tests (`iBaseTests`)

Implement every case listed in docs/07: Radix round-trips (all bases, 0, `UInt64.max`), the design fixtures (2026 → BIN `11111101010` / OCT `3752` / HEX `7EA`; 126₁₆ = `7E`), Base64 fixtures, `legalDigits` counts, `displayBitWidth` boundaries (65535/65536, `UInt32.max`/+1), parse errors; ViewModel guards (illegal digit no-op, overflow no-op, empty delete no-op, `canCommit`/`previewValue` agreement); `commit(in:)` against in-memory container incl. `UInt64.max` round-trip. Gate: `xcodebuild test` green on iPhone sim + macOS.

## Phase 4 — UI tests / robot testing (`iBaseUITests`)

1. The single end-to-end journey exactly as scripted in docs/07 (empty → hex entry 7E → commit → readout 126 → history → reload → delete → empty), driven only by accessibility identifiers, `waitForExistence(timeout: 5.0)` + the label-predicate helper.
2. Launch-performance test (`XCTApplicationLaunchMetric`).
3. `AppStoreScreenshotUITests` per docs/08 (three captures with `-ShowcaseData`, `APPSTORE_SCREENSHOT_DIR` env).
4. `Scripts/generate_appstore_assets.swift` composition script per docs/08.
5. Gate: UI tests green on iPhone sim; journey test also green on iPad sim.

## Phase 5 — CI (GitHub Actions)

Create `.github/workflows/ci.yml`:

- Triggers: `push` to `main`, `pull_request`.
- Runner: `macos-15` (or latest available), pinned Xcode via `xcode-select`.
- Steps: checkout → install XcodeGen (`brew install xcodegen`) → `xcodegen generate` → build+test matrix:
  - `platform=iOS Simulator, name=iPhone 16 Pro` — unit + UI tests
  - `platform=iOS Simulator, name=iPad Pro 13-inch (M4)` — unit + UI journey
  - `platform=macOS` — build + unit tests
- Use `-resultBundlePath`, upload result bundles and captured screenshots as artifacts on failure and on success respectively.
- Concurrency group cancelling superseded runs; fail fast off so all destinations report.
- Add a `README.md` badge and a short "CI" section documenting how to run the same commands locally.

Verify workflow YAML with `actionlint` if available (install via brew), otherwise by careful review. Simulator names must exist on the chosen runner image — check the runner's available devices list and adjust.

## Phase 6 — Final verification

1. Run the full local equivalent of CI (all three destinations) and paste a summary of results.
2. Walk docs/09 checklist; output it with boxes ticked/unticked and a reason per unticked box.
3. `git init` if needed, commit in logical chunks (skeleton / utilities+model / features / tests / CI), and print the `gh repo create … --push` command for the user to run (do not create the repo without asking).

Work through phases with a task list; do not skip gates. If anything in this command proves impossible (e.g. a simulator name, an OS API), flag it and propose the closest alternative before deviating.
