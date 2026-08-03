# 09 — Defaults Checklist

Quick reference. Every new app should tick these before shipping; any unticked box needs an explicit, flagged reason.

## Stack

- [ ] 100% SwiftUI, universal iPhone + iPad, recent-OS target
- [ ] SwiftData persistence (`@Model`, `@Query`, `ModelContext`), CloudKit-ready defaults on stored properties
- [ ] Typed navigation: coordinator enum + `NavigationStack(path:)`, `@Binding var path` passed down
- [ ] No unjustified third-party dependencies (SPM only)

## Structure

- [ ] Feature folders under `Features/`, subviews as `Parent+Child.swift` extensions
- [ ] Design tokens (`Spacing`, `CornerRadius`, `BorderWidth`, `IconSize`) in `Utilities/`, referenced fluently — zero magic numbers
- [ ] View-specific dimensions as `static let` constants on the view
- [ ] Semantic colors in asset catalog with light/dark variants
- [ ] MVVM only where earned; view model in-file as `extension View { final class ViewModel }`
- [ ] Model owns business logic as guarded methods; identity-based `Hashable`

## Visual & motion

- [ ] System font; monospaced digits + `@ScaledMetric` + `.contentTransition(.numericText())` for changing numbers
- [ ] Curated color presets + full picker escape hatch; user colors stored as hex
- [ ] Runtime adaptive contrast for text on variable backgrounds (`@Transient textColor`)
- [ ] Soft color-matched shadows, hairline low-opacity strokes, system materials for chrome
- [ ] Springs only (response 0.18–0.28, damping 0.68–0.86), tied to real events
- [ ] Press-scale `ButtonStyle` on interactive elements
- [ ] Haptics on primary actions; fully usable silently; no sound
- [ ] Adaptive grid via size class — one layout, no iPad fork

## UX

- [ ] Progressive disclosure: search past threshold, sort in a menu, controls hidden when empty
- [ ] Native `ContentUnavailableView` for empty and no-results states
- [ ] Destructive actions confirmed via `.confirmationDialog`
- [ ] Editor forms: live preview card, throwing centralized validation, `canSave`-gated Save, keyboard Done button

## Accessibility

- [ ] Identifiers + labels + values on all interactive/dynamic elements (doubling as UI-test hooks)
- [ ] Dynamic Type via scaled metrics; graceful `minimumScaleFactor` shrink
- [ ] Light/dark automatic via asset catalog

## Quality & tooling

- [ ] Unit tests: model rules, validation, save/delete against in-memory container
- [ ] UI tests: one end-to-end journey via accessibility identifiers + launch-performance test
- [ ] `-UITesting` (empty in-memory) and `-ShowcaseData` (seeded in-memory) launch flags
- [ ] `#Preview` on every feature view, seeded with edge cases (long names, extremes, white/black backgrounds)
- [ ] Scripted, reproducible App Store screenshots (UI-test capture + composition script)
- [ ] App Intents / Shortcuts for the primary action
