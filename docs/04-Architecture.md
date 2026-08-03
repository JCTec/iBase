# 04 — Architecture

Four pillars: a thin `@main` entry, typed navigation via a coordinator enum, a SwiftData history model, and MVVM only where earned — which in iBase means exactly one view model, on `EntryView`.

**Flagged adaptations** (see `00-ProjectBrief.md`): `HistoryEntry` is an immutable snapshot, so the guarded business rules (digit legality, 64-bit overflow) live in `EntryView.ViewModel` and the `Radix` utility rather than on the model. There is no shared create/edit editor; `EntryView.ViewModel` inherits the editor pattern's throwing-validation shape instead.

## 1. App entry — `iBaseApp.swift`

```swift
import AppIntents
import SwiftUI
import SwiftData

@main
struct iBaseApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      HistoryEntry.self,
    ])
    let launchArguments = ProcessInfo.processInfo.arguments
    let usesTemporaryStore = launchArguments.contains("-UITesting") || launchArguments.contains("-ShowcaseData")

    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: usesTemporaryStore)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      iBaseNavigationView()
        .preferredColorScheme(.dark) // dark-only, flagged in 00
    }
    .modelContainer(sharedModelContainer)
  }
}
```

## 2. Typed navigation — coordinator enum + `NavigationStack`

The root owns the `NavigationPath` **and the workspace state**: the current value and selected base. Screens receive them as `@Binding`s — history selection and keypad commits write back through the binding, so the readout is always in sync.

```swift
import SwiftUI

enum iBaseCoordinator: Hashable {
  case entry
  case history
}

struct iBaseNavigationView: View {
  static let defaultValue: UInt64 = 2026 // design reference value

  @State private var path = NavigationPath()
  @State private var currentValue: UInt64 = Self.defaultValue
  @State private var selectedBase: Int = HistoryEntry.defaultBase

  var body: some View {
    NavigationStack(path: self.$path) {
      ReadoutView(
        path: self.$path,
        currentValue: self.$currentValue,
        selectedBase: self.$selectedBase
      )
      .navigationDestination(for: iBaseCoordinator.self) { route in
        switch route {
          case .entry:
            EntryView(
              path: self.$path,
              currentValue: self.$currentValue,
              viewModel: .init(base: self.selectedBase)
            )
            .navigationBarBackButtonHidden(true) // immersive: provides its own ← BACK control
          case .history:
            HistoryView(
              path: self.$path,
              currentValue: self.$currentValue,
              selectedBase: self.$selectedBase
            )
            .navigationTitle("History")
        }
      }
    }
  }
}
```

Conventions: pop-to-root is `self.path = NavigationPath()`; safe pop is `if self.path.count > 0 { self.path.removeLast() }`; `EntryView` is the immersive screen — back button hidden, own close control (the design's `← BACK`).

## 3. Model layer — SwiftData snapshot

`UInt64` is not a SwiftData/CloudKit-storable type, so the stored property is the `Int64` bit pattern with the real value surfaced as `@Transient`. CloudKit-ready: defaults on every stored property.

```swift
import SwiftUI
import SwiftData

@Model
final class HistoryEntry {
  static let defaultBase = 10

  var id: UUID = UUID()
  var valueBitPattern: Int64 = 0
  var enteredBase: Int = HistoryEntry.defaultBase
  var createdAt: Date = Date()

  @Transient var value: UInt64 {
    return UInt64(bitPattern: self.valueBitPattern)
  }

  // Derived UI values every view agrees on.
  @Transient var enteredDigits: String {
    return Radix.string(from: self.value, base: self.enteredBase)
  }

  init(value: UInt64, enteredBase: Int = HistoryEntry.defaultBase, createdAt: Date = Date()) {
    self.id = UUID()
    self.valueBitPattern = Int64(bitPattern: value)
    self.enteredBase = enteredBase
    self.createdAt = createdAt
  }

  init() {
    self.id = UUID()
    self.valueBitPattern = 0
    self.enteredBase = HistoryEntry.defaultBase
    self.createdAt = Date()
  }
}

extension HistoryEntry: Hashable, Equatable {
  static func == (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
```

Rules kept from the house style: `static let default…` for non-trivial defaults; identity-based `Hashable`/`Equatable` on `id`; a parameterless convenience `init()`. Entries are immutable after insert — there are no mutation methods to guard (flagged; the guards moved to input, below).

`HistoryView` reads `@Query(sort: \HistoryEntry.createdAt, order: .reverse)` directly and derives filtered output in a computed `visibleEntries` — no fetch-controller ceremony.

## 3b. Domain utility — `Utilities/Radix.swift`

Pure, stateless conversion logic shared by every screen and fully unit-testable:

```swift
import Foundation

public enum Radix {
  public static let minimumBase = 2
  public static let maximumBase = 36

  /// Uppercase digits for bases 2–36 (e.g. 2026 base 16 → "7EA").
  public static func string(from value: UInt64, base: Int) -> String {
    return String(value, radix: base, uppercase: true)
  }

  /// Throws on illegal digits; nil-guards handled by the caller's keypad, so this backs paste/intents too.
  public static func value(from digits: String, base: Int) throws -> UInt64 {
    guard let value = UInt64(digits, radix: base) else {
      throw ParseError.invalidDigits(digits, base: base)
    }
    return value
  }

  /// Big-endian bytes, leading zero bytes stripped: 2026 → 0x07EA → "B+o=". Zero → "AA==".
  public static func base64String(from value: UInt64) -> String

  /// The legal digit characters for a base, in keypad order: "0"…"9", "A"…"Z" prefix.
  public static func legalDigits(for base: Int) -> [Character]

  /// Smallest of 16/32/64 that contains the value's highest set bit (collapsing bit field).
  public static func displayBitWidth(for value: UInt64) -> Int

  public enum ParseError: LocalizedError, Equatable {
    case invalidDigits(String, base: Int)
    // errorDescription per case
  }
}
```

## 4. MVVM — only where earned: `EntryView.ViewModel`

`ReadoutView` and `HistoryView` have no view models. `EntryView` has real orchestration — per-digit legality, overflow guarding, commit-to-history — declared **inside an extension of the view, in the same file**:

```swift
extension EntryView {
  enum InputError: LocalizedError, Equatable {
    case illegalDigit(Character)
    case overflow

    var errorDescription: String? {
      switch self {
        case .illegalDigit(let digit):
          return "\(digit) is not a digit in this base."
        case .overflow:
          return "Value exceeds the 64-bit maximum."
      }
    }
  }

  final class ViewModel: ObservableObject {
    @Published var digits: String = ""
    @Published var base: Int
    @Published var errorMessage: String?

    init(base: Int = HistoryEntry.defaultBase) {
      self.base = base
    }

    var canCommit: Bool {
      return !self.digits.isEmpty
    }

    /// Live decimal preview — the design's "= 126₁₀ so far".
    var previewValue: UInt64? {
      return try? Radix.value(from: self.digits, base: self.base)
    }

    func isLegal(_ digit: Character) -> Bool {
      return Radix.legalDigits(for: self.base).contains(digit)
    }

    /// Guarded no-op on illegal digit or 64-bit overflow — the keypad dims, it never errors.
    func append(_ digit: Character) {
      guard self.isLegal(digit) else { return }

      let candidate = self.digits + String(digit)
      guard (try? Radix.value(from: candidate, base: self.base)) != nil else { return } // overflow

      self.digits = candidate
    }

    func deleteLastDigit() {
      guard !self.digits.isEmpty else { return }
      self.digits.removeLast()
    }

    /// Throwing, centralized validation + persistence — the editor pattern's shape, applied to entry.
    @discardableResult
    func commit(in modelContext: ModelContext) throws -> HistoryEntry {
      let value = try Radix.value(from: self.digits, base: self.base)
      let entry = HistoryEntry(value: value, enteredBase: self.base)

      modelContext.insert(entry)
      try modelContext.save()
      return entry
    }
  }
}
```

The pattern's signatures matter:

- **Validation is throwing and centralized** in `Radix.value(from:base:)`; `previewValue`/`canCommit` derive from the same source so the commit button and the live preview can never disagree.
- **The view model receives `ModelContext` as a parameter** (`commit(in:)`) — it never stores it.
- The view holds it as `@StateObject var viewModel: ViewModel`, injected via the coordinator.
- The view wraps `commit` in do/catch, routes failures to `viewModel.errorMessage` → `.alert`, and on success writes `entry.value` to the `currentValue` binding and pops.
