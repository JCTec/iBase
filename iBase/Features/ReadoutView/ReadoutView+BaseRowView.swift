import SwiftUI

extension ReadoutView {
  /// One row per base 2–36 plus Base64. Tapping a row selects that base for the next entry
  /// session; the Base64 row is present but unselectable — the keypad only types 2–36 (docs/00).
  struct BaseRowView: View {
    /// 44.0 is the platform minimum hit target — these rows are the primary way to pick a base.
    static let minimumHeight: CGFloat = 44.0
    static let labelWidth: CGFloat = 44.0
    static let digitsMinimumScaleFactor: CGFloat = 0.5

    let base: Int
    let value: UInt64
    let isSelected: Bool
    let action: () -> Void

    private var isSelectable: Bool {
      return self.base <= Radix.maximumBase
    }

    private var digits: String {
      return Radix.displayString(from: self.value, base: self.base)
    }

    private var foregroundColor: Color {
      return self.isSelected ? Color.accent : Color.text
    }

    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        HStack(alignment: .firstTextBaseline, spacing: .spacing.medium) {
          Text(Radix.label(for: self.base))
            .font(.caption.monospaced())
            .tracking(1.2)
            .foregroundStyle(self.isSelected ? Color.accent : Color.dimmed)
            .frame(width: Self.labelWidth, alignment: .leading)

          Spacer(minLength: .spacing.small)

          Text(self.digits)
            .font(.body.monospaced())
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(self.foregroundColor)
            .lineLimit(2)
            .minimumScaleFactor(Self.digitsMinimumScaleFactor)
            .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, .spacing.medium)
        .padding(.vertical, .spacing.small)
        .frame(minHeight: Self.minimumHeight)
        .frame(maxWidth: .infinity)
        .background(
          Color.accent.opacity(self.isSelected ? 0.12 : 0.0),
          in: RoundedRectangle(cornerRadius: .cornerRadius.medium)
        )
        .overlay(
          RoundedRectangle(cornerRadius: .cornerRadius.medium)
            .stroke(
              self.isSelected ? Color.accent.opacity(0.4) : Color.text.opacity(0.08),
              lineWidth: .borderWidth.standard
            )
        )
        // An unselected row's fill is fully transparent, and the label is a `Text | Spacer | Text`
        // — without this the gap between the two labels is not tappable, so most of a wide row
        // (iPad, Mac) silently ignores taps.
        .contentShape(RoundedRectangle(cornerRadius: .cornerRadius.medium))
      })
      .buttonStyle(.press)
      .disabled(!self.isSelectable)
      .animation(.spring(response: 0.22, dampingFraction: 0.8), value: self.isSelected)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Radix.label(for: self.base))
      .accessibilityValue(self.digits)
      .accessibilityIdentifier("baseRow-\(self.base)")
      // `children: .ignore` collapses the button, so the trait is restored explicitly — the row
      // must still read (and be queried) as a button.
      .accessibilityAddTraits(self.isSelected ? [.isButton, .isSelected] : [.isButton])
    }
  }
}
