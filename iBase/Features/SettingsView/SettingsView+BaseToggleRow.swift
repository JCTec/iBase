import SwiftUI

extension SettingsView {
  /// One switch per base. The sample value is the point: you pick bases by recognising what they
  /// look like, not by remembering what "base 12" means.
  struct BaseToggleRow: View {
    /// The design reference value, so every row shows the same number in its own base.
    static let sampleValue: UInt64 = 2026

    let base: Int
    let isVisible: Bool
    let onChange: (Bool) -> Void

    private var binding: Binding<Bool> {
      return Binding(
        get: {
          return self.isVisible
        },
        set: { newValue in
          self.onChange(newValue)
        }
      )
    }

    private var baseLabel: String {
      guard self.base != Radix.base64Base else {
        return "BASE64" // an encoding's name, not a word — untranslated like BIN/OCT/HEX/B64
      }
      // Interpolated rather than a positional `%1$lld` format, so this shares one catalog key with
      // the readout's `Text("BASE \(base)")` instead of adding a second unit to translate.
      return String(localized: "BASE \(self.base)")
    }

    /// "HEX, BASE 16" — the row's two lines read as one element.
    private var rowAccessibilityLabel: String {
      return String(
        format: String(
          localized: "%1$@, %2$@",
          comment: "Accessibility label for a Settings row: a radix label then its base, \"HEX, BASE 16\""
        ),
        Radix.label(for: self.base),
        self.baseLabel
      )
    }

    var body: some View {
      Toggle(isOn: self.binding, label: {
        HStack(alignment: .firstTextBaseline, spacing: .spacing.medium) {
          VStack(alignment: .leading, spacing: .spacing.small / 2.0) {
            Text(Radix.label(for: self.base))
              .font(.body.weight(.bold).monospaced())
              .foregroundStyle(Color.text)

            Text(self.baseLabel)
              .font(.caption2.monospaced())
              .tracking(1.0)
              .foregroundStyle(Color.dimmed)
          }

          Spacer(minLength: .spacing.small)

          Text(Radix.displayString(from: Self.sampleValue, base: self.base))
            .font(.caption.monospaced())
            .monospacedDigit()
            .foregroundStyle(Color.dimmed)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
      })
      .toggleStyle(.switch)
      .tint(Color.accent)
      .padding(.horizontal, .spacing.medium)
      .padding(.vertical, .spacing.small)
      .frame(minHeight: Self.minimumHeight)
      .background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
      .overlay(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
      )
      // A `Toggle` wrapped in its own padding and background stops behaving like a settings row:
      // only the switch itself responds, and tapping the label — the big obvious target — does
      // nothing. This gives the whole row back its tap. The switch keeps handling its own.
      .contentShape(RoundedRectangle(cornerRadius: .cornerRadius.medium))
      .onTapGesture {
        self.onChange(!self.isVisible)
      }
      .listRowInsets(EdgeInsets(
        top: .spacing.small / 2.0,
        leading: .spacing.medium,
        bottom: .spacing.small / 2.0,
        trailing: .spacing.medium
      ))
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)
      .accessibilityLabel(self.rowAccessibilityLabel)
      .accessibilityIdentifier("baseVisibilityToggle-\(self.base)")
    }
  }
}

extension SettingsView.BaseToggleRow {
  static let minimumHeight: CGFloat = 56.0
}
