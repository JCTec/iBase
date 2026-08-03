# 02 — Project Structure

## Targets

```
iBase/               main app target (SwiftUI multiplatform: iPhone, iPad, Mac)
iBaseTests/          unit tests (XCTest, @testable import)
iBaseUITests/        UI tests + App Store screenshot capture
Scripts/             automation (screenshot/asset generation)
AppStoreAssets/      generated marketing output
```

## Main target layout

```
iBase/
├── iBaseApp.swift              @main App struct + ModelContainer + App Intents
├── iBaseNavigationView.swift   NavigationStack root + coordinator enum + current-value state
├── HistoryEntry.swift          SwiftData @Model (one file per model, at target root)
├── Features/
│   ├── ReadoutView/
│   │   ├── ReadoutView.swift
│   │   ├── ReadoutView+BitFieldView.swift       collapsing 16/32/64-bit field
│   │   ├── ReadoutView+BaseRowView.swift        one row per base 2–36 + Base64
│   │   └── ReadoutView+PreviewContainer.swift
│   ├── EntryView/
│   │   ├── EntryView.swift                      view model lives in same file
│   │   └── EntryView+KeypadView.swift           radix-aware keypad + key button
│   └── HistoryView/
│       ├── HistoryView.swift
│       └── HistoryView+PreviewContainer.swift
├── Utilities/
│   ├── Spacing.swift
│   ├── Borders.swift           CornerRadius + BorderWidth
│   ├── IconSize.swift
│   └── Radix.swift             base 2–36 + Base64 formatting/parsing for UInt64
├── Assets.xcassets/
│   ├── AppIcon.appiconset
│   └── Colors/                 dark-only semantic colors (see 05)
├── Preview Content/
├── Info.plist
├── LaunchScreen.storyboard
└── iBase.entitlements
```

## Rules

- **Feature folders, named after the main view.** Each screen gets a folder in `Features/` named exactly after its primary view, containing that view and its satellites.
- **Subview files use `ParentView+ChildView.swift`** and declare the child as `extension ParentView { struct ChildView: View { … } }`. `BitFieldView`, `BaseRowView`, and `KeypadView` are nested this way — they belong to one parent each.
- **Private helpers stay `fileprivate`** inside the file that uses them (e.g. the keypad's press `ButtonStyle`).
- **Models live at the target root** — `HistoryEntry.swift` only.
- **Design tokens live in `Utilities/`**, one concern per file. `Radix.swift` joins them: it's a pure value-formatting concern used by every feature.
- **Preview seed data** goes in `FeatureView+PreviewContainer.swift`, not inline in the view file. `EntryView` needs no container (it works on in-memory state until commit).
- **View models are not separate files.** `EntryView.ViewModel` is declared in an extension of `EntryView`, in `EntryView.swift` (see `04`).
- Navigation root and coordinator enum share one small file at the target root.
