import SwiftUI

enum iBaseCoordinator: Hashable {
  case entry
  case history
  case settings
}

/// The root owns the `NavigationPath` **and the workspace state** — the current value and the
/// selected base. Screens receive them as `@Binding`s, so a history selection or a keypad commit
/// writes straight back to the readout (docs/04 §2).
struct iBaseNavigationView: View {
  static let defaultValue: UInt64 = 2026 // design reference value

  @State private var path = NavigationPath()
  @State private var currentValue: UInt64 = Self.defaultValue
  @State private var selectedBase: Int = HistoryEntry.defaultBase
  /// Workspace state, like the value and the base — the root owns it and every screen reads it
  /// through the environment (docs/04 §2).
  @State private var baseVisibility = BaseVisibilityStore.makeDefault()

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
              selectedBase: self.$selectedBase,
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
          case .settings:
            SettingsView(path: self.$path)
              .navigationTitle("Settings")
        }
      }
    }
    .environment(self.baseVisibility)
  }
}
