# 00 — Project Brief

Phase 2 answers, recorded verbatim. This is the contract every other doc embodies.

## App name

**iBase** (bundle-friendly: `iBase`). Targets: `iBase`, `iBaseTests`, `iBaseUITests`.

## One-sentence purpose

A live number-base converter: the value is always shown in every base 2–36 plus Base64 at once — "the number is a readout, not a text field."

## Primary model

`HistoryEntry` — an immutable snapshot auto-saved each time a value is committed from the keypad:

- `value: UInt64` (stored as `valueBitPattern: Int64` for SwiftData/CloudKit compatibility, surfaced as a `@Transient UInt64`)
- `enteredBase: Int` (default 10)
- `createdAt: Date` (default now)

Entries are never edited — created on commit, deleted from the history list. Input rules (digit legality per base, 64-bit overflow) are the guarded logic; they live in `EntryView.ViewModel` and the `Radix` utility because the model is a snapshot, not the thing being mutated (flagged adaptation of "logic on the model").

## Screens (coordinator routes)

1. **ReadoutView** (root) — current value, bit field, live rows for every base 2–36 + Base64, base switcher. Nothing to submit; it's already converted.
2. **EntryView** (`.entry`) — radix-aware keypad. Digits illegal in the current base are dimmed and dead, not hidden. Live `= N₁₀ so far` preview. Commit saves a `HistoryEntry` and updates the readout.
3. **HistoryView** (`.history`) — list of past entries; tapping one loads it into the readout. Added beyond the design's two screens because persistence = conversion history.

## Primary action

**Open the app** — the App Intent is open-app only ("Open iBase"). Heavy haptics go to keypad digit presses; commit gets the emphasis pulse.

## Decisions on defaulted questions

- **User-chosen colors: NO.** Dark-only instrument panel, single green accent. Drops hex storage, presets, picker, and runtime adaptive-contrast machinery. *(Template conflict, flagged and accepted.)*
- **Platforms:** iPhone + iPad + **Mac** (SwiftUI multiplatform), latest major OS targets. Forced dark appearance.
- **Prominent changing numbers: YES** — monospaced digits + `.contentTransition(.numericText())` everywhere a value renders.
- **CloudKit:** later; model stays CloudKit-ready (defaults on every stored property).
- **Value width:** 64-bit unsigned. No negatives, no arbitrary precision.
- **Base64 semantics:** encode the value's big-endian bytes with leading zero bytes stripped (2026₁₀ = 0x07EA → `B+o=`). "RADIX 2–64" in the design reads as bases 2–36 plus Base64 as a special row.
- **Bit field:** collapses to the significant width boundary (16/32/64 bits) rather than always rendering 64 squares; design shows `MSB·15` for 2026.

## Explicitly out of scope

- Negative numbers / two's complement display
- Values beyond `UInt64.max` (arbitrary precision)
- Light appearance
- User-chosen colors of any kind
- CloudKit sync (now), account systems, analytics, social anything
- Sound (haptics only, per template)

## Template rules adapted (never silently dropped)

1. **Dark-only** replaces light/dark asset variants; adaptive contrast replaced by fixed dimmed/live text states (`05`, `06`).
2. **Custom keypad** replaces "lean on system controls" — the keypad *is* the product; it still uses system buttons, haptics, and accessibility underneath (`06`).
3. **Monospaced type is the design language**, not just for digits — template says system font; we use the system monospaced design (`06`).
4. **Model logic placement** — input invariants live in `EntryView.ViewModel` + `Radix` utility since `HistoryEntry` is immutable (`04`).
5. **No editor form** — the shared create/edit editor pattern doesn't apply; `EntryView.ViewModel` inherits its throwing-validation shape instead (`04`).
