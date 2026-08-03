# Human checklist — release automation

Everything below needs a person with access to the Apple Developer account. None of it could be done
or verified in the environment this automation was built in — see `BLOCKED.md` for exactly what was
and was not proven.

Work top to bottom; each step unblocks the next.

---

## 1. Create the App Store Connect API key

The lanes authenticate with an API key, never an Apple ID and password — no two-factor prompt, it
survives a password change, and it is the only workable option in CI.

- [ ] App Store Connect → **Users and Access → Integrations → App Store Connect API**
- [ ] Create a key with the **App Manager** role
- [ ] Download the `.p8` **once** — Apple will not let you download it again
- [ ] Note the **Key ID** and the **Issuer ID** from the same page
- [ ] Store all three as repository secrets:

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | the Key ID |
| `ASC_ISSUER_ID` | the Issuer ID |
| `ASC_KEY_CONTENT` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` — the **base64** of the file, not its path |
| `IBASE_TEAM_ID` | your Developer Team ID (`S8662L649U` is the team that owns the local Developer ID certificate) |

- [ ] Keep the `.p8` in a password manager, **not** in the repository. `.gitignore` already blocks
      `*.p8` and `AuthKey_*.p8`, but the safest copy is the one that was never in the working tree.

## 2. Register the app

- [ ] Confirm `com.JCTechnologies.iBase` exists as an App ID in the Developer portal. It did not at
      the time this was written — no provisioning profile for that identifier was installed.
- [ ] Create the app record in App Store Connect (iOS, and macOS if shipping to the Mac App Store)

## 3. Add a distribution certificate

The machine this was built on holds a **Developer ID Application** certificate and an **Apple
Development** certificate, but **no Apple Distribution certificate** — so no App Store build, iOS or
Mac, can be signed yet.

- [ ] Create an **Apple Distribution** certificate

## 4. Set up match — only if you want CI to sign

`setup_signing!` falls back to the local keychain when `MATCH_GIT_URL` is unset, which is fine for
cutting releases from one machine. It **fails loudly on CI**, deliberately, because a runner has no
keychain worth falling back to.

- [ ] Create a **private** git repository for the certificates
- [ ] `bundle exec fastlane match init`
- [ ] Generate each type you need: `appstore`, `development`, and `developer_id` for macOS
- [ ] Share the passphrase through a password manager — never in the repository, an issue, or chat
- [ ] Add `MATCH_GIT_URL`, `MATCH_PASSWORD`, and `MATCH_GIT_BASIC_AUTHORIZATION` as secrets
- [ ] Run `bundle exec fastlane certificates` on a clean machine and confirm it succeeds

## 5. Resolve the gym packaging block

`BLOCKED.md` §1 documents this in full: gym mis-detects the platform of this multiplatform target
and fails to package the macOS build, even though the underlying `xcodebuild` archive, export, and
signature are all verified correct.

- [ ] Either apply the recommended fix (a small `scripts/build-macos-developer-id.sh` that fastlane
      wraps), **or** confirm `build_mac_app` behaves correctly inside the real lane
- [ ] Do not ship `mac release_developer_id` until one of those is done

## 6. First beta

- [ ] `bundle exec fastlane ios beta`
- [ ] Confirm the build appears in TestFlight and finishes processing
- [ ] Install it on a device from TestFlight and confirm it launches

## 7. macOS Developer ID — the second-machine test

This is the step that catches entitlement and notarization mistakes, and it **cannot** be done on the
build machine: the build machine trusts its own certificate, so a broken artifact still opens there.

- [ ] `bundle exec fastlane mac release_developer_id`
- [ ] Confirm the lane reports the ticket stapled and Gatekeeper accepting it
- [ ] Copy the `.app` to a machine that has **never built this app**
- [ ] Confirm it opens with **no Gatekeeper warning** and does not quit immediately. An instant quit
      means an entitlement the Developer ID certificate cannot authorise — check which entitlements
      file was signed in

## 8. Store metadata and screenshots

- [ ] `bundle exec fastlane ios screenshots`, then review every image at full size
- [ ] Confirm they show the **real app in use** and would satisfy guideline 2.3.3 — not a title card,
      splash, or login screen
- [ ] Confirm the marketing copy is current and typo-free
- [ ] Upload and confirm App Store Connect accepts every required display family. Only **iPhone
      6.9"** and **iPad 13"** are mandatory (verified 2026-08-03); everything else is derived
- [ ] macOS screenshots must still be produced **by hand** — there is no simulator, so no automated
      path. See the platform note in `docs/RELEASE_AUTOMATION.md`

## 9. Submit

- [ ] `bundle exec fastlane ios release` uploads but does **not** submit — that is deliberate
- [ ] Review the build in App Store Connect
- [ ] Submit for review by hand, or re-run with `submit:true` once you are sure
