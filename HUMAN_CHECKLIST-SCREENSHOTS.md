# Human checklist — App Store screenshots

CI produces the store images; it cannot tell you whether they are *good*. Everything below needs a
person to look.

This is short on purpose. Signing, TestFlight, API keys, and match are all gone: CI no longer builds
or uploads anything, so none of it applies. Distribution is done locally from Xcode.

---

## Produce the images

- [ ] `Actions → Release → Run workflow`, or push a `v*` tag
- [ ] Wait for the run to finish green — it validates on iPhone, iPad, and macOS first, then captures
- [ ] Download **`appstore-images-<run>`**

Locally the equivalent is `bundle exec fastlane ios screenshots`, or `/appstore-assets` in Claude
Code.

## Review every image at full size

Not a sample — every one. Every real defect this pipeline has shipped passed a zero exit code and was
obvious the moment someone opened the picture.

- [ ] **Guideline 2.3.3** — each image shows the app genuinely in use, not a title card, splash, or
      login screen. Apple rejects screenshots that are not the real app.
- [ ] **The screen is current.** Compare against the app as it is today. Stale composites have
      previously shown a removed cursor, a missing screen, and an outdated number of base rows.
- [ ] **Headline is fully legible** and does not collide with the device shot.
- [ ] **Populated, not empty.** No empty states, no spinners, no zero values.
- [ ] **Count and sizes.** 4 screens × 2 devices = 8 images. `iPhone-6.9` at 1320×2868, `iPad-13` at
      2064×2752.
- [ ] **Copy is current** and free of typos.

If something is wrong, fix the cause and regenerate. Never hand-edit an image — the next run
overwrites it.

## Upload

- [ ] Upload to App Store Connect and confirm both display families are accepted
- [ ] **macOS screenshots must still be captured by hand** — there is no Mac simulator, so no
      automated path exists

## Not covered by any of this

- [ ] Building, signing, and uploading the app itself — done locally from Xcode's Organizer
