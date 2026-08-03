# 05 — Design Tokens

Single source of truth for spacing, radii, borders, and icon sizes. Each is a caseless `enum` of `CGFloat` values, plus a `CGFloat` extension so call sites read `.spacing.medium`, `.cornerRadius.large`, `.borderWidth.standard`, `.iconSize.small`.

Copy these three files **verbatim** into `Utilities/` — values and names unchanged from the template.

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
  .background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
  .overlay(
    RoundedRectangle(cornerRadius: .cornerRadius.large)
      .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
  )
```

`spacing: .zero` when a stack manages its own padding.

## Colors — dark-only instrument panel

**Flagged adaptation:** iBase is dark-only with a single accent. The template's light/dark variants, user color presets, `ColorPicker`, hex-on-model storage, and runtime adaptive contrast are all **dropped** (see `00-ProjectBrief.md`). What remains:

- **All semantic colors live in the asset catalog** (`Assets.xcassets/Colors/`), surfaced as typed symbols. Never hard-code semantic colors in Swift. Single (Any) appearance — values *are* the dark values; the app forces `.preferredColorScheme(.dark)`.

  | Asset name | Role | Reference value |
  |---|---|---|
  | `background` | App background | `#0B0B0C` near-black |
  | `panel` | Cards, input surfaces | `#131316` |
  | `text` | Primary text/digits | `#F2F2F0` off-white |
  | `accent` | The one green — live digits, set bits, cursor, tint | `#7ED321`-family lime |
  | `dimmed` | Secondary labels, illegal keypad digits, unset bits | `text` at 0.35–0.45 |

  Reference values come from the design PNG; sample the final artwork before committing them, but the *names* are fixed.

- **Contrast is a design-time gate, not runtime code:** `text`/`accent` on `background`/`panel` must pass WCAG AA; `dimmed` must stay ≥ the large-text floor while still reading as "dead". Verify once, in review, per `09`.
- **Opacity is the texture system:** chrome fills `0.08`, pressed/active key fills `0.12`, hairline strokes `0.14`–`0.18`, secondary text `0.72`–`0.82` — always derived from `text` or `accent`, never new colors.
