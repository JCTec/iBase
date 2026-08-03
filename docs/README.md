# iBase — Project Documentation

App-specific build documentation for **iBase**, a live number-base converter (bases 2–36 + Base64). Generated from the house iOS template; every rule here is already specialized for this app.

## Files

| File | Contents |
|---|---|
| `00-ProjectBrief.md` | The contract: purpose, model, screens, scope, adapted template rules |
| `01-Principles.md` | Guiding principles and non-negotiables |
| `02-ProjectStructure.md` | Folder layout, file naming, target layout |
| `03-CodeStyle.md` | Swift formatting and idiom rules |
| `04-Architecture.md` | App entry, coordinator, `HistoryEntry` model, `EntryView.ViewModel` |
| `05-DesignTokens.md` | Spacing / radius / border / icon tokens, dark-only color system |
| `06-UIPatterns.md` | Readout, bit field, keypad, motion, haptics, accessibility |
| `07-Testing.md` | Unit tests, the end-to-end UI journey, previews, launch flags |
| `08-Tooling.md` | App Intents, App Store screenshot automation |
| `09-Checklist.md` | iBase's live shipping checklist |

## How to use

1. Create the SwiftUI multiplatform project (iPhone + iPad + Mac) per `02`.
2. Copy token files from `05` into `Utilities/`; set up the dark-only color assets.
3. Build entry + navigation from `04`, features per `06`, styled per `03`.
4. Wire tests and tooling from `07` / `08`.
5. Verify against `09` before shipping.

If a requirement conflicts with a rule here, flag it and propose an alternative — never silently drop it.
