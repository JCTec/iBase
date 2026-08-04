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
| **Settings** | Choose which bases the readout shows — most people live in three or four of them |

Tap the readout card (or **ENTER VALUE**) to open the keypad. On a Mac or an iPad with a hardware
keyboard you can just type: the same per-base validation applies, so `E` types in hex and does
nothing at all in decimal. `return` commits, `delete` backspaces, `esc` cancels.

### Visible bases

Bases are stored in `UserDefaults` through a `UserDefault` property wrapper where **an absent key
reads as the default** — so a new device shows BIN, OCT, DEC, HEX and Base64 with no first-launch
seeding, no `register(defaults:)`, and no migration. Flipping a switch writes an explicit
`true`/`false`; *Restore defaults* deletes the keys rather than overwriting them, so a future change
to the default set still reaches devices that never customised it.

The full specification lives in [`docs/`](docs/) (00–09). Those documents are the contract; this
README only describes how to build and test.

## Requirements

- Xcode 26.5 or later (iOS 26 / macOS 26 SDKs)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

`project.yml` is the source of truth; `iBase.xcodeproj` is generated and git-ignored. That includes
signing and versions — settings changed through Xcode's UI are discarded by the next
`xcodegen generate`, so edit `project.yml` instead.

Privacy policy: <https://pdfhost.io/v/Quvw53LjUd_iBase-Privacy-Policy> (source:
`iBase-Privacy-Policy.pdf`). Store copy and identifiers live in [`docs/10-StoreListing.md`](docs/10-StoreListing.md).

## Build

```sh
brew install xcodegen
xcodegen generate
open iBase.xcodeproj
```

## CI

Two workflows, neither of which needs a secret:

| Workflow | Trigger | Runs | Artifacts |
|---|---|---|---|
| `ci.yml` | push to `main`, PR | tests on iPhone sim, iPad sim, and macOS | result bundles, on failure only |
| `release.yml` | `v*` tag, manual dispatch | full tests, then App Store screenshots | branded store images + raw captures |

CI does not build, sign, or upload the app — distribution is done locally from Xcode. See
[`docs/RELEASE_AUTOMATION.md`](docs/RELEASE_AUTOMATION.md).

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
  -only-testing:iBaseUITests/iBaseUITests/testSettingsControlsWhichBaseRowsAppear \
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
bundle exec fastlane ios screenshots
```

That captures both devices with `snapshot` and then composes the branded store images.

Inside Claude Code, `/appstore-assets` runs the same lane and then verifies the output — dimensions,
clipped headlines, and stale screens are all checked by looking at the images, which is where every
defect this pipeline has shipped was actually visible.

Raw captures land in `build/screenshots/`; the finished store images land in
`AppStoreAssets/<device>/` — `iPhone-6.9` (1320×2868) and `iPad-13` (2064×2752), the only two
families App Store Connect requires. Marketing copy lives in
`Scripts/generate_appstore_assets.swift`, which auto-shrinks each headline to fit and **fails the
run** rather than clipping it.

## Tests

- **`iBaseTests`** — `Radix` round-trips across every base including `0` and `UInt64.max`, the
  Base64 fixtures, `displayBitWidth` boundaries, view-model input guards, and `commit(in:)` against
  an in-memory `ModelContainer`.
  Hardware-keyboard entry is covered here too, in `KeyboardInputTests`: XCUITest cannot drive a
  real keyboard on the simulator, so the policy is asserted directly — including that the keyboard
  and the keypad agree on legality for every base × digit pair.
- **`iBaseUITests`** — one end-to-end journey (empty → hex entry `7E` → commit → readout → history
  → reload → delete → empty) driven entirely through accessibility identifiers, the settings
  journey (show a hidden base, hide a default one, restore), tap-to-enter, the empty-bases state, a
  launch-performance test, and the App Store capture test.
