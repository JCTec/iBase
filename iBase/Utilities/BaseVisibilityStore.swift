import Foundation
import Observation

/// Which base rows the readout renders.
///
/// Cross-feature state, so it sits in `Utilities/` for the same reason `Radix` does: every screen
/// reads it and none of them owns it (flagged addition to the docs/02 tree).
///
/// `UserDefaults` is the source of truth and every key is optional — see `UserDefault`. A base the
/// user has never touched simply reads its default, so there is no first-launch initialisation
/// anywhere in the app. `visibleBases` is an observable mirror kept in step on every write, which is
/// what SwiftUI actually watches.
@Observable
final class BaseVisibilityStore {
  /// Visible on a device that has never been touched: the four bases everyone reads, plus Base64.
  static let defaultVisibleBases: Set<Int> = [2, 8, 10, 16, Radix.base64Base]

  private static let keyPrefix = "baseVisible."

  static func storageKey(for base: Int) -> String {
    return "\(BaseVisibilityStore.keyPrefix)\(base)"
  }

  static func isVisibleByDefault(_ base: Int) -> Bool {
    return BaseVisibilityStore.defaultVisibleBases.contains(base)
  }

  @ObservationIgnored private let store: UserDefaults

  private(set) var visibleBases: Set<Int>

  init(store: UserDefaults = .standard) {
    self.store = store
    self.visibleBases = BaseVisibilityStore.loadVisibleBases(from: store)
  }

  /// A throwaway suite under the UI-testing flags, mirroring the in-memory model container in
  /// `iBaseApp` — tests must never inherit (or overwrite) a real person's chosen bases.
  static func makeDefault() -> BaseVisibilityStore {
    let launchArguments = ProcessInfo.processInfo.arguments
    let usesTemporaryStore = launchArguments.contains("-UITesting") || launchArguments.contains("-ShowcaseData")

    guard usesTemporaryStore else {
      return BaseVisibilityStore()
    }

    let suiteName = "iBase.temporary"
    guard let suite = UserDefaults(suiteName: suiteName) else {
      return BaseVisibilityStore()
    }

    suite.removePersistentDomain(forName: suiteName)
    let store = BaseVisibilityStore(store: suite)

    // Marketing captures show every base at once — which is the app's whole pitch, and fills a 13"
    // iPad instead of leaving two thirds of it empty. Rows running off the bottom edge is wanted
    // here, not a defect: a list that continues past the frame implies depth.
    // Showcase-only. The shipping default is still the five in `defaultVisibleBases`.
    if launchArguments.contains("-ShowcaseData") {
      Radix.displayBases.forEach { base in
        store.setVisible(true, for: base)
      }
    }

    return store
  }

  /// The rows the readout draws, in canonical order: 2–36 then Base64.
  var visibleDisplayBases: [Int] {
    return Radix.displayBases.filter { base in
      return self.visibleBases.contains(base)
    }
  }

  var isShowingDefaults: Bool {
    return self.visibleBases == BaseVisibilityStore.defaultVisibleBases
  }

  func isVisible(_ base: Int) -> Bool {
    return self.visibleBases.contains(base)
  }

  func setVisible(_ isVisible: Bool, for base: Int) {
    self.flag(for: base).wrappedValue = isVisible
    self.reloadVisibleBases()
  }

  func toggleVisibility(of base: Int) {
    self.setVisible(!self.isVisible(base), for: base)
  }

  /// Forgets every stored choice rather than writing the defaults over them.
  func restoreDefaults() {
    Radix.displayBases.forEach { base in
      self.flag(for: base).reset()
    }

    self.reloadVisibleBases()
  }

  private func flag(for base: Int) -> UserDefault<Bool> {
    return BaseVisibilityStore.flag(for: base, in: self.store)
  }

  private func reloadVisibleBases() {
    self.visibleBases = BaseVisibilityStore.loadVisibleBases(from: self.store)
  }

  private static func flag(for base: Int, in store: UserDefaults) -> UserDefault<Bool> {
    return UserDefault(
      BaseVisibilityStore.storageKey(for: base),
      default: BaseVisibilityStore.isVisibleByDefault(base),
      store: store
    )
  }

  private static func loadVisibleBases(from store: UserDefaults) -> Set<Int> {
    let visible = Radix.displayBases.filter { base in
      return BaseVisibilityStore.flag(for: base, in: store).wrappedValue
    }

    return Set(visible)
  }
}
