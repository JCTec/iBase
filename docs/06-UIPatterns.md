# 06 — UI Patterns

Recurring view-layer patterns for iBase's three screens. Combine with the tokens from `05-DesignTokens.md`.

**Dropped from the template (flagged in `00`):** runtime adaptive contrast, user color presets/picker, color-matched card shadows (replaced by hairline strokes on the flat panel — the instrument aesthetic is shadowless). **Adapted:** monospaced type is the app-wide design language, not just for digits.

## Typography — monospaced instrument panel

System monospaced design everywhere; Dynamic Type via `@ScaledMetric`:

```swift
@ScaledMetric private var readoutFontSize: CGFloat = 92.0

Text(Radix.string(from: self.currentValue, base: self.selectedBase))
  .font(.system(size: self.readoutFontSize, weight: .bold, design: .monospaced))
  .lineLimit(1)
  .minimumScaleFactor(0.32)
  .monospacedDigit()
  .contentTransition(.numericText())
```

Labels and chrome (`INPUT`, `RADIX 2–64`, `MSB · 15`) use `.font(.caption.monospaced())` with tracking, `Color.dimmed`.

## The readout card

Flat `Color.panel` rect, hairline stroke, no shadow:

```swift
.background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
.overlay(
  RoundedRectangle(cornerRadius: .cornerRadius.medium)
    .stroke(Color.text.opacity(0.14), lineWidth: .borderWidth.standard)
)
```

Every value display animates with a spring keyed to the value; changing base triggers `.contentTransition(.numericText())` on every row at once.

## Bit field — `ReadoutView.BitFieldView`

A row of squares for the significant width (`Radix.displayBitWidth(for:)` → 16/32/64): set bits fill `Color.accent`, unset bits `Color.text.opacity(0.08)`. `MSB · n` / `k BITS SET` / `0 · LSB` caption row in dimmed mono caps. Width changes (crossing 16→32 bits) animate with a spring. Accessibility: the field is one element, `.accessibilityValue("\(bitsSet) of \(width) bits set")`.

## Base rows — `ReadoutView.BaseRowView`

One row per base 2–36 + Base64: dimmed base label left, value right in mono. Binary groups nibbles (`111 1110 1010`). The selected (entry) base row tints `Color.accent`. Rows are buttons — tapping selects that base for the next entry session; identifier `baseRow-\(base)`.

## Radix-aware keypad — `EntryView.KeypadView`

The core custom control (flagged: it *is* the product). Digits `0–9 A–Z` in an adaptive grid; each key:

```swift
Button(action: {
  self.keyGenerator.impactOccurred()
  self.viewModel.append(digit)
}, label: {
  Text(String(digit))
    .font(.title2.weight(.bold).monospaced())
    .foregroundColor(isLegal ? Color.text : Color.dimmed)
    .frame(maxWidth: .infinity, minHeight: Self.keyMinimumHeight)
    .background(Color.text.opacity(isLegal ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
})
.buttonStyle(PressButtonStyle())
.disabled(!isLegal)
.accessibilityIdentifier("keypadKey-\(digit)")
```

Illegal digits are **dimmed and dead, not hidden** — the grid never reflows when the base changes; legality recomputes from `viewModel.isLegal(_:)`. Hardware keyboard (iPad/Mac): the same legality gate via `.onKeyPress`.

## Standard icon button (44pt hit target)

For `← BACK`, delete, history:

```swift
Button(action: {
  self.close()
}, label: {
  Image(systemName: "chevron.backward")
    .font(.title3.weight(.bold))
    .foregroundColor(Color.text)
    .frame(width: 44.0, height: 44.0)
    .background(Color.text.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
})
.buttonStyle(.plain)
.accessibilityLabel("Back")
.accessibilityIdentifier("backButton")
```

Reusable ones become a parameterized `ActionButton` struct nested in the view's extension (`action`, `imageName`, `accessibilityLabel`, `accessibilityIdentifier`).

## Press feedback — custom `ButtonStyle`

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

`UIImpactFeedbackGenerator(style: .heavy)` as a `let` on `EntryView`, fired on every legal digit press (the primary interaction). `.rigid`/lighter for delete and base changes. Commit fires the emphasis pulse below. Pressing a dead digit: no haptic, no motion — dead means dead. No sound anywhere. (Generators are iOS/iPadOS; on Mac these calls no-op behind a small wrapper.)

## Motion

- Springs only, tight and physical: `response` 0.18–0.28, `dampingFraction` 0.68–0.86, always tied to a real event.
- The `= 126₁₀ so far` preview and all readout rows: `.monospacedDigit()` + `.contentTransition(.numericText())` + spring keyed to the value.
- SF Symbol reactions: `.symbolEffect(.bounce, value:)` on the history icon when a commit lands.
- Commit emphasis pulse:

  ```swift
  func playCommitFeedback() {
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

## Chrome over the panel

Sort menu, search field, header labels: `.regularMaterial` / `.ultraThinMaterial` + hairline `Color.text.opacity(0.08)` stroke, fixed 40–44pt height. No chrome that isn't load-bearing.

## Adaptive layout

One layout that adapts — no separate iPad/Mac code path. Keypad and history grid via `LazyVGrid` `.adaptive(minimum:)` with the minimum switched on size class:

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var layout: [GridItem] {
  let minimumWidth = self.horizontalSizeClass == .regular ? Self.regularKeyMinimumWidth : Self.keyMinimumWidth
  return [
    GridItem(.adaptive(minimum: minimumWidth), spacing: .spacing.medium)
  ]
}
```

On regular widths the readout and base rows sit side by side; compact stacks them.

## Progressive disclosure

- History search appears only past a threshold: `var shouldShowSearch: Bool { return self.entries.count >= 10 }`; clear the query when it hides (`.onChange`).
- History sort options live in a `Menu` wrapping a `Picker`, driven by a `CaseIterable` enum with `systemImageName` per case.
- Controls row renders only when there is data; Clear History lives in the menu.

## Empty and error states

Native `ContentUnavailableView` for empty history and no-search-results, each with its own accessibility identifier (`emptyHistoryView`, `noSearchResultsView`). Never hand-build these.

## Entry screen (replaces the template's editor-form pattern — flagged)

No `Form`; the design is an immersive typing surface. It keeps the editor pattern's guarantees:

- Live preview (`= N₁₀ so far`) derives from the same `Radix` parse as `canCommit` — they can never disagree.
- Commit button disabled by `!viewModel.canCommit`.
- `← BACK` is the cancellation action (discards, pops); commit saves, updates the readout binding, pops.
- Save failures surface through `.alert` bound to `viewModel.errorMessage`.
- Destructive actions (Clear History in `HistoryView`) always confirm via `.confirmationDialog` with `titleVisibility: .visible`.

## Accessibility (always on)

- Every interactive/dynamic element: `.accessibilityIdentifier` (stable, camelCase — doubling as UI-test hooks), `.accessibilityLabel`, `.accessibilityValue` where a value exists (readout: current value + base; bit field: bits set).
- Per-instance identifiers interpolate the entity: `keypadKey-\(digit)`, `baseRow-\(base)`, `historyEntry-\(entry.enteredDigits)`.
- Rows/cards: `.accessibilityElement(children: .contain)`.
- Dynamic Type via `@ScaledMetric`; `minimumScaleFactor` shrink on the big readout; destructive confirmation dialogs.
- Dimmed keypad digits stay visible to VoiceOver as disabled — the "learn the alphabet by seeing it shrink" idea must survive non-visually.
