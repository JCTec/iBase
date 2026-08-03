# 09 — iBase Shipping Checklist

The project's live checklist. Every box ticks before shipping; any unticked box needs an explicit, flagged reason. Items struck from the template are listed at the bottom with their reasons — nothing was silently dropped.

## Stack

- [ ] 100% SwiftUI, multiplatform iPhone + iPad + Mac, latest-OS targets
- [ ] SwiftData persistence (`HistoryEntry`), CloudKit-ready defaults on stored properties (`valueBitPattern` bridging verified with `UInt64.max`)
- [ ] Typed navigation: `iBaseCoordinator` + `NavigationStack(path:)`, `@Binding path` + `currentValue`/`selectedBase` passed down
- [ ] Zero third-party dependencies (SPM only if ever justified)

## Structure

- [ ] Feature folders `ReadoutView/`, `EntryView/`, `HistoryView/`; subviews as `Parent+Child.swift` extensions
- [ ] Design tokens (`Spacing`, `CornerRadius`, `BorderWidth`, `IconSize`) in `Utilities/`, referenced fluently — zero magic numbers
- [ ] `Radix.swift` holds all conversion logic; no base math inline in views
- [ ] View-specific dimensions as `static let` constants on the view
- [ ] Semantic colors (`background`, `panel`, `text`, `accent`, `dimmed`) in asset catalog
- [ ] MVVM only where earned: exactly one view model, `EntryView.ViewModel`, in-file
- [ ] Input invariants guarded (`append` no-ops on illegal digit/overflow); identity-based `Hashable` on the model

## Visual & motion

- [ ] System **monospaced** type app-wide; `@ScaledMetric` + `.contentTransition(.numericText())` on every changing value
- [ ] Dark-only palette passes design-time WCAG check (text/accent on background/panel; dimmed ≥ large-text floor)
- [ ] Flat panels with hairline low-opacity strokes; opacity texture system (0.08 / 0.12 / 0.14–0.18)
- [ ] Bit field collapses at 16/32/64 boundaries; set bits in accent; width change animates
- [ ] Springs only (response 0.18–0.28, damping 0.68–0.86), tied to real events
- [ ] Press-scale `ButtonStyle` on keypad keys and buttons
- [ ] Heavy haptics on legal digit presses, commit pulse; dead keys silent; fully usable silently, no sound
- [ ] Adaptive grid via size class — one layout, no iPad/Mac fork

## UX

- [ ] Keypad digits illegal in current base are dimmed and dead, **not hidden** — grid never reflows
- [ ] `= N₁₀ so far` preview and commit button derive from the same parse (can never disagree)
- [ ] Progressive disclosure: history search past 10 entries, sort in a menu, controls hidden when empty
- [ ] Native `ContentUnavailableView` for empty history and no-results
- [ ] Clear History confirmed via `.confirmationDialog` (`titleVisibility: .visible`)
- [ ] Entry screen: back discards, commit saves + updates readout + pops; failures via `.alert`

## Accessibility

- [ ] Identifiers + labels + values on all interactive/dynamic elements (`keypadKey-\(digit)`, `baseRow-\(base)`, `historyEntry-…`)
- [ ] Dimmed keys exposed to VoiceOver as disabled, still discoverable
- [ ] Dynamic Type via scaled metrics; `minimumScaleFactor` on the big readout
- [ ] Bit field reads as one element with a meaningful value

## Quality & tooling

- [ ] Unit tests: `Radix` round-trips (incl. 0, `UInt64.max`, Base64 `B+o=` fixture), view-model guards, commit against in-memory container
- [ ] UI tests: the end-to-end journey (`07`) + launch-performance test
- [ ] `-UITesting` (empty in-memory) and `-ShowcaseData` (seeded, readout at 2026) launch flags
- [ ] `#Preview` on every feature view, seeded with edge cases (0, `UInt64.max`, base 2, base 36)
- [ ] Scripted App Store screenshots (capture test + composition script, incl. Mac size)
- [ ] `OpeniBaseIntent` + shortcuts phrases wired

## Struck from the template (with reasons — see `00`)

- ~~Curated color presets + picker; user colors as hex~~ — no user colors; fixed instrument palette
- ~~Runtime adaptive contrast (`@Transient textColor`)~~ — fixed palette; contrast verified at design time instead
- ~~Light/dark asset variants~~ — dark-only by design
- ~~Soft color-matched shadows~~ — flat, shadowless instrument aesthetic; hairline strokes carry depth
- ~~Editor form with live preview card~~ — no editor; Entry screen keeps the pattern's validation guarantees
