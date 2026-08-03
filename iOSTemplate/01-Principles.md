# 01 — Guiding Principles

These principles override "the popular way." When a specific app conflicts with one, flag it and propose an alternative rather than dropping it.

## Focus over features
One clear purpose, executed well. No account systems, analytics dashboards, or social layers unless explicitly requested. Scope discipline is a feature.

## Native and modern
100% SwiftUI on a recent OS target. Use the platform's newest first-party frameworks (SwiftData, App Intents, symbol effects, numeric content transitions, materials). Lean on the system look — personality comes from color and motion, not from re-skinning native controls.

## Legibility is non-negotiable
Text must always be readable, including on user-chosen or dynamic backgrounds. Compute contrast at runtime rather than assuming (see `06-UIPatterns.md`).

## Tactile and physical
Interactions feel like real objects: haptics on primary actions, spring animations, press-scale feedback. Every animation ties to a real event — never decorative or idle motion. The app must be fully usable silently; carry feedback with haptics, not sound.

## Consistency through tokens
Spacing, radii, borders, icon sizes, and colors are defined once as tokens and referenced everywhere (`.spacing.medium`, `.cornerRadius.large`). No magic numbers scattered across views. View-specific fixed dimensions (a card height, a 44pt hit target) live as named `static let` constants on the view, not inline literals.

## Structure where complexity earns it
Simple views read and mutate the model directly. A screen gets an `ObservableObject` view model only when it has real orchestration: validation, staged edits, save/delete flows. Don't wrap a one-line action in a view model.

## Calm by default
Progressive disclosure — hide search, sort, and advanced controls until the data volume or context earns them. Keep the default screen quiet. Tuck secondary actions into menus.

## No unnecessary dependencies
Reach for a package only when it solves a real problem the platform doesn't (e.g. a color-contrast utility). Justify each one.
