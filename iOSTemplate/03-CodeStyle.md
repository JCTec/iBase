# 03 — Code Style

Swift formatting and idiom rules, as observed in production code.

## Formatting

- **2-space indentation** everywhere.
- **`switch` cases indented one level deeper** than the `switch` keyword:

  ```swift
  switch route {
    case .create:
      // …
    case .edit(let item):
      // …
  }
  ```

- **Explicit `self.`** for all property and method access inside types. This is deliberate and consistent — always `self.name`, `self.path.append(…)`, never bare `name`.
- **Explicit `return`** in computed properties and functions, even single-expression ones:

  ```swift
  var isEditing: Bool {
    return self.item != nil
  }
  ```

- **CGFloat literals carry a decimal point:** `44.0`, `80.0`, `0.12` — not `44`.
- Trailing-closure `Button` style with labeled closures:

  ```swift
  Button(action: {
    self.save()
  }, label: {
    Text("Save")
  })
  ```

- Multiline initializer calls put each argument on its own line when there are 3+ arguments.

## Naming

- Views: `NounView` (`ItemsListView`, `EditItemView`). Navigation root: `MyAppNavigationView`. Coordinator enum: `MyAppCoordinator`.
- Actions are verbs on the model (`incrementValue()`, `resetValue()`) or the view (`saveItem()`, `closeEditor()`).
- Booleans read as assertions: `canSave`, `isEditing`, `shouldShowSearch`, `allowsNegativeValue`, `isShowingDeleteConfirmation`.
- Accessibility identifiers are camelCase and stable: `addItemButton`, `saveItemButton`, `openItem-\(name)` for per-instance elements.
- Enum-backed UI options conform to `String, CaseIterable, Identifiable` with `var id: Self { self }` and expose a `systemImageName` computed property.

## Constants

- **No magic numbers.** Layout dimensions become `static let` on the view:

  ```swift
  struct ItemsListView: View {
    static let cardMinimumWidth: CGFloat = 160.0
    static let regularCardMinimumWidth: CGFloat = 220.0
  }
  ```

- Model defaults become `static let` on the model (`static let defaultIncrement = 1`) and are referenced via `Self.` in initializers.
- Shared visual constants come from the token enums (`05-DesignTokens.md`).

## View composition

- Long `body`s are forbidden. Decompose into **computed subview properties** in declaration order of appearance: `titleView`, `controlsView`, `searchView`, `contentView`, then `body` last, then action `func`s below `body`.
- `body` reads as a table of contents:

  ```swift
  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      self.titleView
      self.controlsView
      self.contentView
    }
  }
  ```

- Use `// MARK:` headers in token/utility files; feature views rely on the property ordering instead.

## Error handling

- Validation errors are a nested `enum ValidationError: LocalizedError, Equatable` with `errorDescription` per case.
- Views catch thrown errors and surface them via a published `errorMessage` bound to an `.alert`.
- `guard` early-exits over nested `if`s; guard-and-return for no-op invalid actions.
