# 02 — Project Structure

## Targets

```
MyApp/               main app target
MyAppTests/          unit tests (XCTest, @testable import)
MyAppUITests/        UI tests + App Store screenshot capture
Scripts/             automation (screenshot/asset generation)
AppStoreAssets/      generated marketing output (committed or gitignored per project)
```

## Main target layout

```
MyApp/
├── MyAppApp.swift              @main App struct + ModelContainer + App Intents
├── MyAppNavigationView.swift   NavigationStack root + coordinator enum
├── Item.swift                  SwiftData @Model (one file per model, at target root)
├── Features/
│   ├── ItemsListView/
│   │   ├── ItemsListView.swift
│   │   ├── ItemsListView+CardView.swift        subviews as extensions
│   │   └── ItemsListView+PreviewContainer.swift
│   ├── ItemView/
│   │   └── ItemView.swift
│   └── EditItemView/
│       └── EditItemView.swift                  view model lives in same file
├── Utilities/
│   ├── Spacing.swift
│   ├── Borders.swift           CornerRadius + BorderWidth
│   └── IconSize.swift
├── Assets.xcassets/
│   ├── AppIcon.appiconset
│   └── Colors/                 named colors with light/dark variants
├── Preview Content/
├── Info.plist
├── LaunchScreen.storyboard
└── MyApp.entitlements
```

## Rules

- **Feature folders, named after the main view.** Each screen gets a folder in `Features/` named exactly after its primary view (`ItemsListView/`), containing that view and its satellites.
- **Subview files use `ParentView+ChildView.swift`** and declare the child as `extension ParentView { struct ChildView: View { … } }`. Child views used by only one parent are nested this way, not made top-level types.
- **Private helpers stay `fileprivate`** inside the file that uses them (e.g. a custom `ButtonStyle` used by one card).
- **Models live at the target root**, one `@Model` class per file, named after the entity.
- **Design tokens live in `Utilities/`**, one concern per file.
- **Preview seed data** for a feature goes in `FeatureView+PreviewContainer.swift`, not inline in the view file.
- **View models are not separate files.** A screen's `ViewModel` is declared in an `extension` of the screen's view, in the same file (see `04-Architecture.md`).
- Navigation root and coordinator enum share one small file at the target root.
