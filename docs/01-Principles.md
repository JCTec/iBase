# 01 — Guiding Principles

These principles override "the popular way." When a requirement conflicts with one, flag it and propose an alternative rather than dropping it.

## Focus over features

One clear purpose: show a number in every base at once. No account systems, analytics, or social layers. Scope discipline is a feature — see the out-of-scope list in `00-ProjectBrief.md` (no negatives, no >64-bit, no light mode).

## Native and modern

100% SwiftUI, multiplatform (iPhone + iPad + Mac), latest major OS targets. SwiftData for history, App Intents, symbol effects, numeric content transitions, materials. Personality comes from the single green accent and motion — not from re-skinning native controls. The keypad is custom because it *is* the product (flagged in `00`), but it's built from system buttons, haptics, and accessibility primitives.

## Legibility is non-negotiable

The palette is fixed (dark panel, off-white text, green accent), so contrast is verified **at design time** against WCAG ratios instead of computed at runtime — the runtime adaptive-contrast machinery is dropped (flagged in `00`). Dimmed states (illegal keypad digits, secondary labels) must stay ≥ the large-text contrast floor.

## Tactile and physical

Interactions feel like an instrument panel: heavy haptics on keypad digits, spring animations, press-scale feedback, numeric transitions when the value or base changes. Every animation ties to a real event — never decorative or idle motion. Fully usable silently; feedback is haptic, never sound.

## Consistency through tokens

Spacing, radii, borders, icon sizes, and colors defined once as tokens (`.spacing.medium`, `.cornerRadius.large`). No magic numbers. View-specific dimensions (keypad key height, bit-square size, the 44pt hit target) are named `static let` constants on the view.

## Structure where complexity earns it

`ReadoutView` and `HistoryView` read models directly — no view models. `EntryView` earns one: digit legality per base, 64-bit overflow guarding, and the commit-to-history flow are real orchestration (`04-Architecture.md`).

## Calm by default

The readout is quiet: value, bit field, base rows. Search in history appears only past 10 entries; clear-history hides in a menu; controls render only when there's data.

## No unnecessary dependencies

Base conversion for 2–36 is `String(_:radix:)` + `UInt64(_:radix:)`; Base64 is `Foundation`. Expected dependency count: **zero**. Anything proposed needs a one-line justification proving the platform can't do it.
