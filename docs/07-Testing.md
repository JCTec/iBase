# 07 — Testing & Previews

Three layers: unit tests for `Radix` + `EntryView.ViewModel` + model, UI tests for the real flow via accessibility identifiers, and previews/showcase data backed by in-memory stores.

## Launch flags

Two arguments control the store (checked in the `@main` container builder, see `04`):

- `-UITesting` — in-memory store, empty. Used by functional UI tests.
- `-ShowcaseData` — in-memory store, seeded with demo data. Used by screenshots, demos, marketing.

Seeding lives on `ReadoutView`, guarded and idempotent:

```swift
.task {
  self.seedShowcaseDataIfNeeded()
}

func seedShowcaseDataIfNeeded() {
  guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.entries.isEmpty else { return }

  [
    HistoryEntry(value: 2026, enteredBase: 10),   // design reference value
    HistoryEntry(value: 126, enteredBase: 16),    // the design's 7E
    HistoryEntry(value: 255, enteredBase: 2),
    HistoryEntry(value: 4096, enteredBase: 8)
  ].forEach { entry in
    self.modelContext.insert(entry)
  }

  try? self.modelContext.save()
}
```

## Unit tests (`iBaseTests`)

`@MainActor final class` XCTestCases, `@testable import iBase`. Cover:

- **`Radix` rules (the app's real business logic):**
  - round-trips for every base 2–36 (`string(from:base:)` ↔ `value(from:base:)`), including `0` and `UInt64.max`
  - the design's fixtures: 2026 → BIN `11111101010`, OCT `3752`, HEX `7EA`; 126 base 16 = `7E`
  - Base64: 2026 → `B+o=`; 0 → `AA==`; leading-zero-byte stripping; `UInt64.max` full 8 bytes
  - `legalDigits(for:)` counts (base 2 → 2 keys, base 16 → 16, base 36 → 36)
  - `displayBitWidth(for:)` boundaries: 0→16, 65535→16, 65536→32, `UInt32.max`→32, `UInt32.max + 1`→64
  - `value(from:base:)` throws `.invalidDigits` on illegal characters and on overflow past `UInt64.max`
- **View-model input rules:** `append` no-ops on illegal digits and on overflow; `deleteLastDigit` no-ops when empty; `canCommit`/`previewValue` derive from the same parse; base switching re-evaluates legality.
- **Persistence orchestration:** `commit(in:)` inserts a `HistoryEntry` with the right value/base — against an in-memory `ModelContainer`; `valueBitPattern` round-trips `UInt64.max`:

```swift
@MainActor
final class EntryViewModelTests: XCTestCase {
  func testCommitInsertsHistoryEntry() throws {
    let container = try ModelContainer(
      for: HistoryEntry.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let viewModel = EntryView.ViewModel(base: 16)
    viewModel.append("7")
    viewModel.append("E")

    let entry = try viewModel.commit(in: container.mainContext)

    XCTAssertEqual(entry.value, 126)
    XCTAssertEqual(entry.enteredBase, 16)
  }
}
```

Style: plain descriptive method names (`testAppendIgnoresDigitsIllegalInCurrentBase`, `testBitWidthGrowsAt65536`), arrange-act-assert with blank lines between phases, related fixtures contrasted in one test where it clarifies behavior.

## UI tests (`iBaseUITests`)

- `setUpWithError` sets `continueAfterFailure = false` and `app.launchArguments = ["-UITesting"]`.
- **One end-to-end journey test** covering the core loop, driven entirely through accessibility identifiers:

  1. Launch → readout shows the default value; history is empty (`emptyHistoryView` via `historyButton`).
  2. Back to readout → `baseRow-16` selects hex → `openEntryButton` opens the keypad.
  3. Verify radix-awareness: `keypadKey-E` enabled; switch entry base to 10 and assert `keypadKey-E` is disabled-but-present; switch back to 16.
  4. Type `keypadKey-7`, `keypadKey-E` → preview label reads `= 126₁₀ so far` (label-predicate helper below).
  5. `commitButton` → back on readout: value `126`, `baseRow-2` shows `111 1110`, bit field reports 6 bits set.
  6. `historyButton` → `historyEntry-7E` exists → tap it → readout loads 126.
  7. Delete the entry (swipe/context action) → confirm → `emptyHistoryView` again.

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
struct _ReadoutViewPreview: View {
  @State var path = NavigationPath()
  @State var currentValue: UInt64 = 2026
  @State var selectedBase: Int = 10

  var body: some View {
    ReadoutView(path: self.$path, currentValue: self.$currentValue, selectedBase: self.$selectedBase)
      .modelContainer(Self.previewContainer)
  }
}

extension _ReadoutViewPreview {
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: HistoryEntry.self, configurations: config)

      container.mainContext.insert(HistoryEntry(value: 2026, enteredBase: 10))
      container.mainContext.insert(HistoryEntry(value: 0, enteredBase: 2))
      container.mainContext.insert(HistoryEntry(value: .max, enteredBase: 36))

      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }()
}

#Preview {
  _ReadoutViewPreview()
}
```

Seed previews with edge cases on purpose: `0`, `UInt64.max` (full 64-square bit field + longest strings — the layout stress test), base 2 (longest digit string) and base 36 (densest alphabet), and an `EntryView` preview in base 2 (34 dead keys) and base 36 (none dead). The template's white/black background contrast cases are dropped — fixed palette (flagged in `00`).
