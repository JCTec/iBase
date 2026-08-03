import SwiftUI

/// Which bases the readout shows. Most people live in two or three bases a day; the other
/// thirty-odd are one switch away rather than always on screen.
///
/// Flagged: docs/00 says the value is shown in *every* base at once. Filtering narrows that, so the
/// defaults keep the four everyone reads plus Base64, and nothing is ever removed — only hidden.
struct SettingsView: View {
  static let rowMinimumHeight: CGFloat = 44.0
  static let controlSize: CGFloat = 44.0

  @Binding var path: NavigationPath

  @Environment(BaseVisibilityStore.self) private var baseVisibility

  private var summaryView: some View {
    HStack(spacing: .spacing.small) {
      Text(verbatim: "\(self.baseVisibility.visibleBases.count) OF \(Radix.displayBases.count) VISIBLE")
        .font(.caption.monospaced())
        .tracking(1.2)
        .monospacedDigit()
        .contentTransition(.numericText())
        .foregroundStyle(Color.dimmed)

      Spacer(minLength: .spacing.small)

      // Only earns its place once there is something to restore (docs/01, calm by default).
      if !self.baseVisibility.isShowingDefaults {
        Button(action: {
          self.restoreDefaults()
        }, label: {
          Text("RESTORE DEFAULTS")
            .font(.caption.monospaced())
            .tracking(1.2)
            .foregroundStyle(Color.accent)
        })
        .buttonStyle(.press)
        .accessibilityLabel("Restore default bases")
        .accessibilityIdentifier("restoreDefaultsButton")
      }
    }
    .padding(.horizontal, .spacing.medium)
    .frame(height: Self.controlSize)
    .background(.ultraThinMaterial)
    .overlay(
      RoundedRectangle(cornerRadius: .cornerRadius.medium)
        .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
    )
    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius.medium))
    .animation(.spring(response: 0.24, dampingFraction: 0.82), value: self.baseVisibility.visibleBases)
    .accessibilityElement(children: .contain)
  }

  private var basesListView: some View {
    List {
      ForEach(Radix.displayBases, id: \.self) { base in
        BaseToggleRow(
          base: base,
          isVisible: self.baseVisibility.isVisible(base),
          onChange: { isVisible in
            self.setVisible(isVisible, for: base)
          }
        )
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  var body: some View {
    VStack(spacing: .spacing.medium) {
      self.summaryView
        .padding(.horizontal, .spacing.medium)

      self.basesListView
    }
    .padding(.top, .spacing.medium)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
  }

  private func setVisible(_ isVisible: Bool, for base: Int) {
    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
      self.baseVisibility.setVisible(isVisible, for: base)
    }
  }

  private func restoreDefaults() {
    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
      self.baseVisibility.restoreDefaults()
    }
  }
}

// MARK: Previews

@MainActor
private struct _SettingsViewPreview: View {
  @State var path = NavigationPath()
  @State var baseVisibility: BaseVisibilityStore

  var body: some View {
    NavigationStack {
      SettingsView(path: self.$path)
        .navigationTitle("Settings")
    }
    .environment(self.baseVisibility)
    .preferredColorScheme(.dark)
  }
}

#Preview("Settings · defaults") {
  _SettingsViewPreview(baseVisibility: BaseVisibilityStore(store: .previewStore(named: "defaults")))
}

#Preview("Settings · everything on") {
  _SettingsViewPreview(baseVisibility: {
    let store = BaseVisibilityStore(store: .previewStore(named: "all"))
    Radix.displayBases.forEach { base in
      store.setVisible(true, for: base)
    }
    return store
  }())
}

#Preview("Settings · nothing on") {
  _SettingsViewPreview(baseVisibility: {
    let store = BaseVisibilityStore(store: .previewStore(named: "none"))
    Radix.displayBases.forEach { base in
      store.setVisible(false, for: base)
    }
    return store
  }())
}

extension UserDefaults {
  /// A throwaway suite so a preview never writes into the real app's chosen bases.
  static func previewStore(named name: String) -> UserDefaults {
    let suiteName = "iBase.preview.\(name)"
    guard let suite = UserDefaults(suiteName: suiteName) else {
      return .standard
    }

    suite.removePersistentDomain(forName: suiteName)
    return suite
  }
}
