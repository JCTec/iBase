# iOS App Template

A reproducible, project-agnostic template describing how apps are built in this style (extracted from real production code, Hacking with Swift–adjacent conventions). Feed these files to a human or an AI when scaffolding a new app so the result matches these preferences by default.

**Placeholders used throughout:** `MyApp` = your app name, `Item` = your primary model. Replace both; never replicate the source app's features.

## Files

| File | Contents |
|---|---|
| `01-Principles.md` | Guiding principles and non-negotiables |
| `02-ProjectStructure.md` | Folder layout, file naming, target layout |
| `03-CodeStyle.md` | Swift formatting and idiom rules |
| `04-Architecture.md` | App entry, typed navigation (coordinator), model layer, MVVM-when-earned |
| `05-DesignTokens.md` | Spacing / radius / border / icon-size tokens, color strategy |
| `06-UIPatterns.md` | Views, adaptive contrast, motion, haptics, accessibility |
| `07-Testing.md` | Unit tests, UI tests, previews, launch-flag demo data |
| `08-Tooling.md` | App Intents, App Store screenshot automation |
| `09-Checklist.md` | Quick-reference defaults checklist |

## How to use

1. Start a new SwiftUI iOS project (universal iPhone + iPad, recent OS target).
2. Apply `02-ProjectStructure.md` to lay out folders and targets.
3. Copy the token files from `05-DesignTokens.md` verbatim into `Utilities/`.
4. Build the app entry + navigation from `04-Architecture.md`.
5. Build features following `06-UIPatterns.md`, styled per `03-CodeStyle.md`.
6. Wire tests and tooling from `07-Testing.md` and `08-Tooling.md`.
7. Verify against `09-Checklist.md` before shipping.

If a rule doesn't fit the app being built, flag the conflict and propose an alternative — don't silently drop it.
