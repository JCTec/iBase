import Foundation

/// A `UserDefaults`-backed value that reads as `defaultValue` for as long as the key is absent.
///
/// That absence *is* the first-launch story: a fresh device needs no seeding pass, no
/// `register(defaults:)` call, and no migration — "never written" already means "use the default".
/// The first time the user flips a switch the key becomes an explicit `true`/`false` and stays that
/// way, on that device, forever.
///
/// ```swift
/// @UserDefault("baseVisible.16", default: true) var isHexVisible: Bool
/// ```
@propertyWrapper
struct UserDefault<Value> {
  let key: String
  let defaultValue: Value
  let store: UserDefaults

  init(_ key: String, default defaultValue: Value, store: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.store = store
  }

  var wrappedValue: Value {
    get {
      return self.store.object(forKey: self.key) as? Value ?? self.defaultValue
    }
    nonmutating set {
      self.store.set(newValue, forKey: self.key)
    }
  }

  /// `true` once the user has expressed a preference, as opposed to riding the default.
  var isUserChosen: Bool {
    return self.store.object(forKey: self.key) != nil
  }

  /// Drops back to the default by forgetting the stored value entirely — not by writing the
  /// default over it, so the key stays absent and future default changes still reach this device.
  nonmutating func reset() {
    self.store.removeObject(forKey: self.key)
  }
}
