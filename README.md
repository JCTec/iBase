# iBase

[![CI](https://github.com/OWNER/iBase/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/iBase/actions/workflows/ci.yml)

A live number-base converter: the value is always shown in every base 2–36 plus Base64 at once.

> The number is a readout, not a text field.

SwiftUI multiplatform — iPhone, iPad, and Mac from one codebase. Dark-only instrument panel, one
green accent, monospaced everywhere. Zero third-party dependencies.

| Screen | What it does |
|---|---|
| **Readout** | Current value, collapsing 16/32/64-bit field, a live row for every base 2–36 + Base64 |
| **Entry** | Radix-aware keypad — digits illegal in the current base are dimmed and dead, never hidden |
| **History** | Every committed value, in the base you typed it; tap one to load it back into the readout |

The full specification lives in [`docs/`](docs/) (00–09). Those documents are the contract; this
README only describes how to build and test.

## Requirements

- Xcode 26.5 or later (iOS 26 / macOS 26 SDKs)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

`project.yml` is the source of truth; `iBase.xcodeproj` is generated and git-ignored.

## Build

```sh
brew install xcodegen
xcodegen generate
open iBase.xcodeproj
```

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to `main` and every pull
request, across three destinations with `fail-fast` off so each one reports independently:

| Destination | What runs |
|---|---|
| `platform=iOS Simulator,name=iPhone 17 Pro` | unit tests + all UI tests |
| `platform=iOS Simulator,name=iPad Pro 13-inch (M5)` | unit tests + the end-to-end journey |
| `platform=macOS` | build + unit tests |

Result bundles upload as artifacts when a job fails; captured screenshots upload when it succeeds.

### Running the same commands locally

```sh
xcodegen generate

# iPhone — unit + UI
xcodebuild test -project iBase.xcodeproj -scheme iBase \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath artifacts/iphone.xcresult

# iPad — unit + the journey
xcodebuild test -project iBase.xcodeproj -scheme iBase \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -only-testing:iBaseTests \
  -only-testing:iBaseUITests/iBaseUITests/testConvertCommitReloadAndDeleteJourney \
  -resultBundlePath artifacts/ipad.xcresult

# macOS — build + unit
xcodebuild test -project iBase.xcodeproj -scheme iBase \
  -destination 'platform=macOS' \
  -only-testing:iBaseTests \
  -resultBundlePath artifacts/macos.xcresult
```

Simulator names must exist on the machine — check with `xcrun simctl list devices available` and
substitute if yours differ.

## Launch flags

Both use an in-memory store, so neither touches your real history:

- `-UITesting` — empty store. Used by the functional UI tests.
- `-ShowcaseData` — seeded store (2026₁₀, 7E₁₆, 11111111₂, 10000₈). Used by screenshots and demos.

The `iBase-UITests` scheme runs the app with `-ShowcaseData` already set.

## App Store screenshots

Screenshots come from a command, never by hand, so they regenerate whenever the UI changes.

```sh
# 1. capture
TEST_RUNNER_APPSTORE_SCREENSHOT_DIR="$PWD/AppStoreAssets/captures" \
  xcodebuild test -project iBase.xcodeproj -scheme iBase \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:iBaseUITests/AppStoreScreenshotUITests

# 2. compose into every required App Store dimension
swift Scripts/generate_appstore_assets.swift
```

Output lands in `AppStoreAssets/<device>/` (iPhone 6.9" and 6.5", iPad 13", Mac). Marketing copy
lives in the script, so localized or restyled variants regenerate with the artwork.

## Tests

- **`iBaseTests`** — `Radix` round-trips across every base including `0` and `UInt64.max`, the
  Base64 fixtures, `displayBitWidth` boundaries, view-model input guards, and `commit(in:)` against
  an in-memory `ModelContainer`.
- **`iBaseUITests`** — one end-to-end journey (empty → hex entry `7E` → commit → readout → history
  → reload → delete → empty) driven entirely through accessibility identifiers, a launch-performance
  test, and the App Store capture test.
