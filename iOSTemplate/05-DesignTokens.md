# 05 — Design Tokens

Single source of truth for spacing, radii, borders, and icon sizes. Each is a caseless `enum` of `CGFloat` values, plus a `CGFloat` extension exposing the enum fluently so call sites read `.spacing.medium`, `.cornerRadius.large`, `.borderWidth.standard`, `.iconSize.small`.

Copy these files verbatim into `Utilities/`. Adjust values per project only if the design demands it — the token *names* stay stable.

## `Utilities/Spacing.swift`

```swift
import Foundation

public enum Spacing {
  public static var baseline: CGFloat { Spacing.small }

  public static let small: CGFloat = 8.0
  public static let medium: CGFloat = 16.0
  public static let large: CGFloat = 24.0
  public static let xLarge: CGFloat = 32.0
}

extension CGFloat {
  public static let spacing = Spacing.self
}
```

## `Utilities/Borders.swift`

```swift
import Foundation

// MARK: CornerRadius
public enum CornerRadius {
  public static var small: CGFloat { 4 }
  public static var medium: CGFloat { 6 }
  public static var large: CGFloat { 8 }
}

// MARK: BorderWidth
public enum BorderWidth {
  public static var standard: CGFloat { 1 }
  public static var medium: CGFloat { 2 }
  public static var thick: CGFloat { 4 }
}

extension CGFloat {
  public static let cornerRadius = CornerRadius.self
  public static let borderWidth = BorderWidth.self
}
```

## `Utilities/IconSize.swift`

```swift
import Foundation

public enum IconSize {
  public static let small: CGFloat = 16
  public static let medium: CGFloat = 24
  public static let large: CGFloat = 32
  public static let xLarge: CGFloat = 48
  public static let xxLarge: CGFloat = 96
}

extension CGFloat {
  public static let iconSize = IconSize.self
}
```

## Usage

```swift
VStack(alignment: .leading, spacing: .spacing.small) { … }
  .padding(.horizontal, .spacing.medium)
  .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
  .overlay(
    RoundedRectangle(cornerRadius: .cornerRadius.large)
      .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
  )
```

`spacing: .zero` when a stack manages its own padding.

## Colors

- **All semantic colors live in the asset catalog** (`Assets.xcassets/Colors/`) with light/dark variants, surfaced as typed symbols: `Color.background`, `Color.text`, plus project accents. Never hard-code semantic colors in Swift.
- **User-facing color choices are curated presets first**, full `ColorPicker` as escape hatch. Presets are a small warm/muted palette defined as data:

  ```swift
  struct ColorPreset: Identifiable, Equatable {
    let name: String
    let hex: String

    var id: String { self.hex }

    var color: Color {
      return Color(uiColor: UIColor(hex: self.hex) ?? .white)
    }
  }

  static let colorPresets = [
    ColorPreset(name: "Snow", hex: "ffffff"),
    ColorPreset(name: "Lagoon", hex: "62b6cb"),
    ColorPreset(name: "Mint", hex: "84a59d"),
    ColorPreset(name: "Sun", hex: "f6bd60"),
    ColorPreset(name: "Coral", hex: "f28482"),
    ColorPreset(name: "Indigo", hex: "3d405b"),
    ColorPreset(name: "Ink", hex: "1b1b1e")
  ]
  ```

- User-chosen colors persist as **hex strings** on the model, converted through a `UIColor(hex:)` utility (a small package like ColorKit is an acceptable, justified dependency for hex + contrast math).
- Opacity is the texture system: overlays and chrome derive from the foreground color at low opacity (`0.08` chrome fill, `0.12` button fill, `0.14`–`0.18` strokes, `0.72`–`0.82` secondary text).
