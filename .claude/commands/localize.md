---
description: Add a String Catalog, migrate every user-facing string, then translate to Spanish
---

# Localize iBase

Two phases, strictly in order: **Phase 1** makes the app fully localizable with English as the source language and proves nothing broke. **Phase 2** adds Spanish. Do not start Phase 2 until Phase 1's gate passes.

House rules apply throughout: `docs/03-CodeStyle.md` style, no magic strings scattered — and `project.yml` is the source of truth, so catalog/target changes happen there, never by hand-editing the generated `.xcodeproj` (regenerate with `xcodegen generate`).

## Phase 1 — String Catalog + full migration (English only)

1. **Add the catalog.** Create `iBase/Localizable.xcstrings` (source language `en`) and an `InfoPlist.xcstrings` for localizable Info.plist keys (`CFBundleDisplayName`). Register both in `project.yml` (they live under the existing `iBase` source path — verify XcodeGen picks them up as resources; add `knownRegions`/`developmentLanguage: en` if needed). Regenerate and confirm the catalog appears in the project.

2. **Audit every user-facing string.** Sweep all Swift files under `iBase/`:
   - `Text(...)` literals, `Label(...)`, `navigationTitle(...)`, `ContentUnavailableView` titles/descriptions, `.alert`/`.confirmationDialog` titles and buttons, Menu/Picker labels — these are `LocalizedStringKey` already and will auto-extract on build; just verify each lands in the catalog.
   - **Interpolated accessibility strings** — `accessibilityLabel`, `accessibilityValue`, `accessibilityHint` built with `"\(x) in base \(y)"`-style interpolation. Convert each to a localizable form with positional format specifiers (`String(localized:)` or `LocalizedStringResource`), e.g. `"%1$@ in base %2$lld"`, so target languages can reorder words.
   - **`InputError.errorDescription`** and any other `LocalizedError` text → `String(localized:)`.
   - **App Intent**: `OpeniBaseIntent.title`, `IntentDescription`, shortcut `shortTitle`, and the `phrases` array — all via `LocalizedStringResource`.
   - Explicitly **exclude** from localization: radix output (`Radix.string/label` digit output like `7EA`, `BIN`, `OCT` — these are notation, not prose — decide and document `BIN/OCT/HEX/B64` as unlocalized technical labels), accessibility **identifiers** (test hooks, never localized), launch flags, and asset/color names.

3. **Build to extract.** Run a build so Xcode populates the catalog, then inspect `Localizable.xcstrings` (it's JSON) and verify every string from the audit is present — list any that didn't extract and fix the call site.

4. **Gate — nothing broke.** Full test suite green on iPhone sim + macOS (`bundle exec fastlane test` or the xcodebuild commands in README). The UI tests must still pass **unmodified**, because they drive accessibility identifiers, not labels — if any test matches on a visible English label (the journey test checks a `= 126₁₀ so far`-style label), switch that assertion to identifier + `accessibilityValue`. Commit as `Add String Catalog and migrate all user-facing strings`.

## Phase 2 — Spanish translation

1. Add `es` to the catalog (single `es` localization — neutral Latin American Spanish, serves es-MX and es-ES; matches the store listing in `docs/10-StoreListing.md`).

2. Translate every key in `Localizable.xcstrings` and `InfoPlist.xcstrings` by editing the catalog JSON, setting state `translated` per unit. Terminology must match the published Spanish store copy in `docs/10-StoreListing.md` — e.g. historial (History), campo de bits (bit field), confirmar (commit), base. Keep the instrument-panel voice: all-caps chrome labels stay all-caps (`TYPING` → `ESCRIBIENDO`, `ENTER VALUE` → `INGRESAR VALOR`, `COMMIT` → `CONFIRMAR`, `RESTORE DEFAULTS` → `RESTABLECER VALORES`, `BACK` → `ATRÁS`, `N BITS SET` → `N BITS ACTIVOS`). Translate accessibility labels and Siri phrases too ("Convertir un número con \(.applicationName)"). `MSB`/`LSB`/`BIN`/`OCT`/`HEX`/`B64` stay as-is per the Phase 1 decision.

3. **Do NOT chase layout fit.** No font-size, frame, or truncation changes for Spanish — the maintainer will test fit rigorously on device and report what overflows. Just don't introduce hard truncation that didn't exist: leave existing `lineLimit`/`minimumScaleFactor` values untouched.

4. **Gate.** Build with `-AppleLanguages (es)` scheme argument or a dedicated test run; run the unit suite plus the UI journey once under Spanish to prove identifiers survived translation. Verify the catalog has zero `needs_review`/untranslated units (`plutil`/`jq` over the JSON). Update `docs/09-Checklist.md` with a ticked localization line and note the es localization in `docs/10-StoreListing.md`. Commit as `Add Spanish localization`.

## Report back

Final message: count of localized keys, list of strings deliberately left unlocalized (with the reason), any call sites that needed restructuring for word order, and the exact scheme argument the maintainer should use to run the app in Spanish for the fit pass.
