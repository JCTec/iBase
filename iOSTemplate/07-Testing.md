# 07 — Testing & Previews

Three layers: unit tests for model + view-model logic, UI tests for real flows via accessibility identifiers, and previews/showcase data backed by in-memory stores.

## Launch flags

Two arguments control the store (checked in the `@main` container builder, see `04-Architecture.md`):

- `-UITesting` — in-memory store, empty. Used by functional UI tests.
- `-ShowcaseData` — in-memory store, seeded with demo data. Used by screenshots, demos, marketing.

Seeding lives on the list view, guarded and idempotent:

```swift
.task {
  self.seedShowcaseDataIfNeeded()
}

func seedShowcaseDataIfNeeded() {
  guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.items.isEmpty else { return }

  [
    Item(name: "First", value: 6),
    Item(name: "Second", value: 15)
  ].forEach { item in
    self.modelContext.insert(item)
  }

  try? self.modelContext.save()
}
```

## Unit tests (`MyAppTests`)

`@MainActor final class` XCTestCases, `@testable import MyApp`. Cover:

- **Model business rules:** each mutation method, its guards, and boundary cases (invalid input is a no-op, limits respected, reset behavior).
- **View-model validation:** `validatedValues()` trims/normalizes and throws the right `ValidationError` per bad field; `canSave` mirrors it.
- **Persistence orchestration:** `save(in:)` inserts on create / mutates on edit, `delete(in:)` removes — against an in-memory `ModelContainer`:

```swift
@MainActor
final class ItemTests: XCTestCase {
  func testSaveInsertsNewItem() throws {
    let container = try ModelContainer(
      for: Item.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = EditItemView.ViewModel()
    viewModel.name = "  Habits  "

    let item = try viewModel.save(in: container.mainContext)

    XCTAssertEqual(item.name, "Habits")
  }
}
```

Style: plain descriptive method names (`testDecrementStopsAtZeroUnlessNegativeValuesAreAllowed`), arrange-act-assert with blank lines between phases, multiple related entities exercised in one test when they contrast behaviors.

## UI tests (`MyAppUITests`)

- `setUpWithError` sets `continueAfterFailure = false` and `app.launchArguments = ["-UITesting"]`.
- **One end-to-end journey test** covering the core loop: create → interact → verify → edit → delete → back to empty state. Drive it entirely through accessibility identifiers.
- Assert async UI with `waitForExistence(timeout: 5.0)` and a small label-predicate helper:

```swift
private func wait(for element: XCUIElement, toHaveLabel label: String, timeout: TimeInterval = 3.0) {
  let predicate = NSPredicate(format: "label == %@", label)
  expectation(for: predicate, evaluatedWith: element)
  waitForExpectations(timeout: timeout)
}
```

- Include a launch-performance test with `XCTApplicationLaunchMetric()`.

## Previews

Every feature view gets a `#Preview`. Views needing SwiftData get a preview wrapper + seeded in-memory container in a `+PreviewContainer.swift` file:

```swift
@MainActor
struct _ItemsListViewPreview: View {
  @State var path = NavigationPath()

  var body: some View {
    ItemsListView(path: self.$path)
      .modelContainer(Self.previewContainer)
  }
}

extension _ItemsListViewPreview {
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: Item.self, configurations: config)

      container.mainContext.insert(Item(name: "Test", value: 23))
      container.mainContext.insert(Item(name: "Edge Case", value: 0))

      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }()
}

#Preview {
  _ItemsListViewPreview()
}
```

Seed previews with edge cases on purpose: long names, zero values, extreme colors (pure white / pure black backgrounds) to exercise adaptive contrast.
