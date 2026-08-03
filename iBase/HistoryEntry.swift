import SwiftUI
import SwiftData

/// An immutable snapshot, auto-saved each time a value is committed from the keypad (docs/00).
///
/// `UInt64` is not a SwiftData/CloudKit-storable type, so the stored property is the `Int64` bit
/// pattern with the real value surfaced as `@Transient`. CloudKit-ready: every stored property
/// carries a default, so turning sync on later is a capability change, not a migration.
@Model
final class HistoryEntry {
  static let defaultBase = 10

  var id: UUID = UUID()
  var valueBitPattern: Int64 = 0
  var enteredBase: Int = HistoryEntry.defaultBase
  var createdAt: Date = Date()

  var value: UInt64 {
    return UInt64(bitPattern: self.valueBitPattern)
  }

  // Derived UI values every view agrees on.
  var enteredDigits: String {
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

// Flagged deviation from docs/04 §3: the doc spells out an identity-based `==`/`hash(into:)` in an
// extension. On the current SDK that no longer compiles — `@Model` expands to a `PersistentModel`
// conformance that already supplies identity-based `Hashable`/`Equatable` (keyed on
// `persistentModelID`), so a hand-written `==` is ambiguous with it ("multiple matching functions
// named '=='"). The rule the doc is protecting — identity, never value, semantics — is satisfied by
// the synthesised conformance and is pinned by `HistoryEntryTests.testEqualityIsIdentityBased`.
