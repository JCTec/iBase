# BLOCKED

Written per the effort's rule: stop after two failed attempts on the same problem, record exactly
what was tried, and move to the next independent phase rather than guessing.

Two things are blocked. They are unrelated, and only the first is a genuine dead end here.

---

## 1. gym cannot package a macOS build of a multiplatform target

**Status: blocked on tooling behaviour, with a confirmed root cause and a recommended fix.**

### What works — verified, not assumed

The underlying build is correct. Driving `xcodebuild` directly with exactly the settings the lane
uses produces a properly signed Developer ID artifact:

```
** ARCHIVE SUCCEEDED **
** EXPORT SUCCEEDED **

Authority=Developer ID Application: Juan Carlos Estevez Rodriguez (S8662L649U)
Authority=Developer ID Certification Authority
Authority=Apple Root CA
TeamIdentifier=S8662L649U
CodeDirectory … flags=0x10000(runtime)              ← Hardened Runtime applied
Entitlements: com.apple.security.app-sandbox only    ← no App Store-only entitlements
… valid on disk
… satisfies its Designated Requirement
```

So the certificate, the Hardened Runtime setting, the entitlements split, and the export options are
all right. The problem is purely `gym`'s wrapper around them.

### What was tried

| # | Attempt | Result |
|---|---|---|
| 1 | `build_mac_app` with signing identity inside the `xcargs` string | `"iBase" requires a provisioning profile`. Cause: a value containing a space (`Developer ID Application`) does not survive being embedded in `xcargs` |
| 2 | Moved the identity to gym's own `codesigning_identity` + `export_options` | Same error. Reading gym's actual invocation showed why: it passed **`-destination 'generic/platform=iOS'`** — it archived the *iOS* variant of this multiplatform target, and iOS manual signing genuinely does need a profile |
| 3 | Added `destination: "generic/platform=macOS"` | Archive and export both **succeeded**, then gym failed at the packaging step with `[!] IPA invalid` — it still believed it was handling an iOS product |
| 4 | `platform:macOS` passed to gym | `Could not find option 'platform'` — gym has no such option; macOS-ness is inferred, and the inference is what is wrong |

### Root cause

The app target declares `supportedDestinations: [iOS, macOS]`. gym infers the platform from the
scheme rather than being told, and for a target that legitimately supports both it resolves to iOS.
`destination:` fixes the *archive* step but not gym's *packaging* step, which independently decides
it is producing an `.ipa`.

Note attempts 3 and 4 were run through `fastlane run build_app …` rather than through the lane
itself, because the lane calls `asc_api_key` first and no App Store Connect key is available here
(see block 2). It is possible — untested — that `build_mac_app` inside a real `platform :mac` lane
sets the platform correctly where `fastlane run` does not.

### Recommended fix

Have the Developer ID lane shell out to a small `scripts/build-macos-developer-id.sh` doing the
`xcodebuild archive` + `-exportArchive` shown above, and let fastlane handle notarize, staple, and
verify. That is this effort's "wrap, don't replace" principle applied in the direction it actually
points: the verified path is `xcodebuild`, and fastlane genuinely *adds* complexity here rather than
removing it. The lane comment should say so.

**Do not** ship the current `mac release_developer_id` lane without either applying that fix or
confirming that `build_mac_app` behaves differently inside the lane than under `fastlane run`.

---

## 2. No Apple Developer credentials in this environment

**Status: blocked on missing secrets. Expected, not a defect.**

The keychain holds a `Developer ID Application` certificate and an `Apple Development`
certificate — enough to sign a local macOS Developer ID build, which is why block 1 could be
diagnosed at all. It does **not** hold:

- an **Apple Distribution** certificate → no iOS or Mac App Store build can be signed
- an **App Store Connect API key** (`ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT`)
- a provisioning profile for `com.JCTechnologies.iBase` (no profile for that identifier exists)

### What that means for the gates

| Gate | Status |
|---|---|
| Phase 3 — a signed build is produced locally without Xcode intervention | **Met.** Verified above |
| Phase 4 — `ios beta` produces its artifact end to end | **Not met.** Needs a distribution certificate and an ASC key |
| Phase 4 — `ios release` produces its artifact end to end | **Not met.** Same |
| Phase 4 — `mac release` (App Store) produces its artifact | **Not met.** Same |
| Phase 4 — Developer ID notarized, stapled, Gatekeeper-accepted | **Not met.** `notarize` uploads to Apple and needs the ASC key |
| Phase 4 — artifact launches on a second machine | **Not met.** No second machine available |

### What *was* verified without credentials

- Every lane's **missing-secret path fails loudly** and names all missing variables at once, rather
  than continuing and producing an unsigned artifact.
- The **entitlements precondition works**: injecting `com.apple.developer.icloud-services` into the
  Developer ID entitlements file made the lane refuse to build, with the reason spelled out.
- The **Hardened Runtime precondition works** the same way.

These are the failure modes that matter most, and they are the ones that can be tested without an
Apple account.

### To unblock

Follow `HUMAN_CHECKLIST-RELEASE.md`: create the App Store Connect API key, add an Apple Distribution
certificate, then run `bundle exec fastlane ios beta` and confirm the build reaches TestFlight.
