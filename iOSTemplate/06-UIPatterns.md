# 06 — UI Patterns

Recurring view-layer patterns. All snippets are project-agnostic; combine with the tokens from `05-DesignTokens.md`.

## Adaptive contrast (runtime, on the model)

Any element on a user-chosen background computes its foreground color from the contrast ratio — legibility never depends on the user's color choice. Exposed as `@Transient` on the model so every view agrees:

```swift
@Transient var textColor: Color {
  guard let backgroundUIColor = self.backgroundUIColor else { return .lightForeground }
  let contrastRatio = backgroundUIColor.contrastRatio(with: .darkForeground)

  switch contrastRatio {
    case .acceptable, .acceptableForLargeText:
      return .darkForeground
    default:
      return .lightForeground
  }
}
```

## Standard icon button (44pt hit target)

The workhorse control — tinted glyph over a low-opacity fill of the same color:

```swift
Button(action: {
  self.close()
}, label: {
  Image(systemName: "xmark")
    .font(.title3.weight(.bold))
    .foregroundColor(foregroundColor)
    .frame(width: 44.0, height: 44.0)
    .background(foregroundColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
})
.buttonStyle(.plain)
.accessibilityLabel("Close")
.accessibilityIdentifier("closeButton")
```

Reusable action buttons become small parameterized structs (`ActionButton`) nested in the view's extension, taking `action`, `imageName`, `accessibilityLabel`, `accessibilityIdentifier`.

## Press feedback — custom `ButtonStyle`

Interactive elements scale down slightly while pressed, with a spring:

```swift
fileprivate struct PressButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
      .animation(.spring(response: 0.18, dampingFraction: 0.72), value: configuration.isPressed)
  }
}
```

## Haptics

`UIImpactFeedbackGenerator(style: .heavy)` stored as a `let` on the view; fire `impactOccurred()` inside primary actions. Lighter styles for secondary actions. No sound.

## Motion

- Springs only, tight and physical: `response` 0.18–0.28, `dampingFraction` 0.68–0.86.
- Changing numbers: `.monospacedDigit()` + `.contentTransition(.numericText())` + spring keyed to the value.
- SF Symbol reactions: `.symbolEffect(.bounce, value: someValue)`.
- Emphasis pulse: briefly toggle a `@State` scale flag with springs on both edges:

  ```swift
  func playFeedback() {
    self.generator.impactOccurred()

    withAnimation(.spring(response: 0.18, dampingFraction: 0.68)) {
      self.isPulsing = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.86)) {
        self.isPulsing = false
      }
    }
  }
  ```

## Cards

Rounded rect in the item's color, hairline stroke in the adaptive text color, soft **color-matched** shadow:

```swift
.background(
  RoundedRectangle(cornerRadius: .cornerRadius.medium)
    .foregroundColor(item.backgroundColor)
)
.overlay(
  RoundedRectangle(cornerRadius: .cornerRadius.medium)
    .stroke(item.textColor.opacity(0.14), lineWidth: .borderWidth.standard)
)
.shadow(color: item.backgroundColor.opacity(0.22), radius: 14.0, x: 0.0, y: 7.0)
```

Cards that both display controls and open a detail screen layer a clear, fixed-height tap-target `Button` over the top region (`Color.clear.contentShape(Rectangle())`) so inner buttons keep their own hit areas.

## Chrome over colorful content

Sort menus, search fields, toolbars: `.regularMaterial` / `.ultraThinMaterial` background + hairline `Color.text.opacity(0.08)` stroke, fixed 40–44pt height.

## Adaptive layout

One layout that adapts — no separate iPad code path. `LazyVGrid` with `.adaptive(minimum:)`, minimum width switched on size class:

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var layout: [GridItem] {
  let minimumWidth = self.horizontalSizeClass == .regular ? Self.regularCardMinimumWidth : Self.cardMinimumWidth
  return [
    GridItem(.adaptive(minimum: minimumWidth), spacing: .spacing.medium)
  ]
}
```

## Progressive disclosure

- Search appears only past a threshold: `var shouldShowSearch: Bool { return self.items.count >= 10 }`; clear the query when it hides (`.onChange`).
- Sort options live in a `Menu` wrapping a `Picker`, driven by a `CaseIterable` enum with `systemImageName` per case.
- Controls row renders only when there is data.

## Empty and error states

Native `ContentUnavailableView` for both true-empty and no-search-results, each with its own accessibility identifier. Never hand-build these.

## Forms (editor screens)

- `Form` with a live **preview card** section at the top (list row background cleared) showing the entity as it will appear, using the same adaptive-contrast logic.
- Toolbar: `.cancellationAction` Cancel, `.confirmationAction` Save (disabled by `!viewModel.canSave`), destructive trash icon when editing, and a `.keyboard` placement Done button that resigns first responder.
- Inline validation message section when `validationMessage != nil`.
- Destructive actions always confirm via `.confirmationDialog` with `titleVisibility: .visible`.
- Save failures surface through `.alert` bound to `viewModel.errorMessage`.

## Typography

System font only. Prominent numbers: `.system(size:weight:design: .monospaced)` sized via `@ScaledMetric` so Dynamic Type scales it, with `.minimumScaleFactor` for graceful shrink:

```swift
@ScaledMetric private var counterFontSize: CGFloat = 92.0

Text(item.value.formatted())
  .font(.system(size: self.counterFontSize, weight: .bold, design: .monospaced))
  .lineLimit(1)
  .minimumScaleFactor(0.32)
  .monospacedDigit()
  .contentTransition(.numericText())
```

## Accessibility (always on)

- Every interactive/dynamic element: `.accessibilityIdentifier` (stable, camelCase — these double as UI-test hooks), `.accessibilityLabel`, and `.accessibilityValue` where a value exists.
- Per-instance identifiers interpolate the entity: `"openItem-\(item.name)"`.
- Cards: `.accessibilityElement(children: .contain)`; preview cards: `.combine`.
- Dynamic Type via `@ScaledMetric`; light/dark via asset-catalog colors; destructive confirmation dialogs.
