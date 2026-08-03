# 03 — Code Style

Swift formatting and idiom rules. Unchanged from the house style; examples specialized for iBase.

## Formatting

- **2-space indentation** everywhere.
- **`switch` cases indented one level deeper** than the `switch` keyword:

  ```swift
  switch route {
    case .entry:
      // …
    case .history:
      // …
  }
  ```

- **Explicit `self.`** for all property and method access inside types — always `self.digits`, `self.path.append(…)`, never bare `digits`.
- **Explicit `return`** in computed properties and functions, even single-expression ones:

  ```swift
  var canCommit: Bool {
    return !self.digits.isEmpty
  }
  ```

- **CGFloat literals carry a decimal point:** `44.0`, `92.0`, `0.12` — not `44`.
- Trailing-closure `Button` style with labeled closures:

  ```swift
  Button(action: {
    self.viewModel.append(digit)
  }, label: {
    Text(String(digit))
  })
  ```

- Multiline initializer calls put each argument on its own line when there are 3+ arguments.

## Naming

- Views: `NounView` (`ReadoutView`, `EntryView`, `HistoryView`). Navigation root: `iBaseNavigationView`. Coordinator enum: `iBaseCoordinator`.
- Actions are verbs: `append(_:)`, `deleteLastDigit()`, `commit(in:)` on the view model; `openEntry()`, `loadEntry(_:)` on views.
- Booleans read as assertions: `canCommit`, `isLegal(_:)`, `shouldShowSearch`, `isShowingClearConfirmation`, `isPulsing`.
- Accessibility identifiers are camelCase and stable: `openEntryButton`, `commitButton`, `keypadKey-7`, `keypadKey-E`, `historyEntry-2026`, `baseRow-16`.
- Enum-backed UI options conform to `String, CaseIterable, Identifiable` with `var id: Self { self }` and a `systemImageName` computed property (e.g. the history sort options).

## Constants

- **No magic numbers.** Layout dimensions become `static let` on the view:

  ```swift
  struct EntryView: View {
    static let keyMinimumHeight: CGFloat = 56.0
    static let regularKeyMinimumHeight: CGFloat = 64.0
  }
  ```

- Model/domain defaults become `static let` on the type (`HistoryEntry.defaultBase`, `Radix.minimumBase`, `Radix.maximumBase`) and are referenced via `Self.` internally.
- Shared visual constants come from the token enums (`05-DesignTokens.md`).

## View composition

- Long `body`s are forbidden. Decompose into **computed subview properties** in order of appearance — `ReadoutView`: `headerView`, `inputCardView`, `bitFieldView`, `baseRowsView`, then `body` last, then action `func`s below `body`.
- `body` reads as a table of contents:

  ```swift
  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      self.headerView
      self.inputCardView
      self.baseRowsView
    }
  }
  ```

- `// MARK:` headers in token/utility files (`Radix.swift` included); feature views rely on property ordering instead.

## Error handling

- Input errors are a nested `enum InputError: LocalizedError, Equatable` with `errorDescription` per case (`.illegalDigit`, `.overflow`).
- Views catch thrown errors and surface them via a published `errorMessage` bound to an `.alert` (commit/persistence failures); illegal digits and overflow during typing are guarded **no-ops with haptic feedback**, not alerts.
- `guard` early-exits over nested `if`s; guard-and-return for no-op invalid actions (pressing a dead digit does nothing).
