---
description: Capture fresh simulator screenshots and compose the branded App Store images, verifying every one
---

# App Store assets

Regenerate the store images end to end: real simulator captures → branded composites → verified.

`$ARGUMENTS` may name a single device (`iphone`, `ipad`) to regenerate just that one. Default is
both.

## Non-negotiables

**Real pixels only.** Every image depicts the app actually running on a simulator. Never redraw,
mock up, or hand-edit a screen. Apple rejects screenshots that are not the real app (guideline
2.3.3), so a mockup is a submission risk, not a shortcut. If a capture cannot be produced, stop and
say so — do not emit a placeholder.

**Verify by looking.** The composer exiting zero is not evidence. Open the images and check them.
Most of the defects this pipeline has actually shipped — a clipped headline, a stale screen, five
base rows under a headline promising thirty-six — were invisible in the exit code and obvious in the
picture.

**Never weaken a gate to make a run pass.** The readiness waits and the headline overflow check
exist because each one caught a real defect.

## Steps

### 1. Preconditions

- `xcodegen generate` — the `.xcodeproj` is generated and git-ignored, so a clean checkout has none.
- Confirm the simulators in `fastlane/Snapfile` exist: `xcrun simctl list devicetypes`. If one is
  missing, stop and report it with the available list. Do not silently substitute — a different
  device captures at a different size, and the size is the whole point.

### 2. Capture

```sh
bundle exec fastlane ios screenshots
```

This captures with `snapshot` and then runs `Scripts/generate_appstore_assets.swift`, so the two
halves cannot drift apart. Run the lane, not the pieces.

The lane pins the status bar to 9:41 / full battery / full signal and launches with
`-ShowcaseData -UITestScreenshotMode`, so two runs of the same commit produce identical images.

If it fails, read the failure before retrying. A capture test that reports *"appeared but never
became hittable"* means the element exists but is off screen — usually because the content changed,
not because the wait is too strict. Fix the assertion to name an element that is on screen in every
configuration; do not relax the wait.

### 3. Verify — the part that actually matters

Check **every** composed image in `AppStoreAssets/`, not a sample:

- [ ] **Dimensions exact.** `iPhone-6.9` = 1320×2868, `iPad-13` = 2064×2752. These are the only two
      families App Store Connect requires; it derives the rest. Verified against Apple's
      specifications on 2026-08-03 — re-check if a year has passed, the requirements change.
- [ ] **Headline fully legible**, not clipped and not colliding with the device shot. The composer
      auto-shrinks and fails on overflow, but confirm it looks right rather than merely fitting.
- [ ] **The screen shown is the current app.** Compare against what the app renders today. Stale
      composites are the recurring failure here: they have previously shown a removed cursor, a
      missing screen, and an outdated number of base rows.
- [ ] **Populated, not empty.** No empty states, no spinners, no zero values.
- [ ] **Count matches.** One image per screen per device — currently 4 × 2 = 8.
- [ ] **Guideline 2.3.3.** Each image shows the app in use, not a title card, splash, or login
      screen.

Report the dimensions and the file count. If anything is wrong, fix the cause and regenerate —
never hand-edit an image.

### 4. Report

State plainly what was produced and what you checked by eye. If you did not look at an image, say
so rather than implying you did.

## Where things live

| Path | What |
|---|---|
| `fastlane/Snapfile` | devices, locales, launch arguments |
| `iBaseUITests/ScreenshotUITests.swift` | one test per screen; navigation and capture only |
| `Scripts/generate_appstore_assets.swift` | branding — background, eyebrow, headline, device inset |
| `build/screenshots/` | raw captures |
| `AppStoreAssets/` | finished store images, git-ignored |

## Changing the set

- **New screen** — add a `Caption` to the composer and a `testScreenshot…` method to
  `ScreenshotUITests`. Both, or the run fails: the composer errors on a missing capture.
- **New device** — add it to `Snapfile` and a `DeviceSpec` to the composer. `simulatorName` must
  match `Snapfile` exactly, since that is how captures are located. Prefer a device whose native
  capture already equals an accepted size, so nothing is ever rescaled.
- **New copy** — edit the `Caption` headlines. Keep them short: the composer refuses to draw a
  headline it cannot fit legibly, and localized strings run 30–40% longer than English.

## Known gaps

- **No macOS screenshots.** `snapshot` drives XCUITest against simulators, and macOS has none. Mac
  store images must be captured by hand. Do not invent a workaround.
- **Single locale.** The app is not localized; `en-US` is the honest maximum. Adding locales before
  localizing the app produces identical English images under different locale folders.
