import SwiftUI

extension EntryView {
  /// The core custom control — it *is* the product (flagged in docs/00).
  ///
  /// All 36 digits are always rendered: the ones illegal in the current base are dimmed and dead,
  /// never hidden, so the grid does not reflow when the base changes and you learn the alphabet by
  /// watching it shrink (docs/06).
  struct KeypadView: View {
    @ObservedObject var viewModel: ViewModel
    let onKeyPressed: (Character) -> Void

    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var layout: [GridItem] {
      let minimumWidth = self.isRegularWidth ? EntryView.regularKeyMinimumWidth : EntryView.keyMinimumWidth
      return [
        GridItem(.adaptive(minimum: minimumWidth), spacing: .spacing.medium)
      ]
    }

    private var keyMinimumHeight: CGFloat {
      return self.isRegularWidth ? EntryView.regularKeyMinimumHeight : EntryView.keyMinimumHeight
    }

    /// `horizontalSizeClass` is iOS-only; on Mac every window is a regular-width layout.
    private var isRegularWidth: Bool {
      #if os(macOS)
      return true
      #else
      return self.horizontalSizeClass == .regular
      #endif
    }

    var body: some View {
      LazyVGrid(columns: self.layout, spacing: .spacing.medium) {
        ForEach(Radix.keypadDigits, id: \.self) { digit in
          self.keyView(for: digit)
        }
      }
      .animation(.spring(response: 0.24, dampingFraction: 0.82), value: self.viewModel.base)
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Keypad")
    }

    @ViewBuilder
    private func keyView(for digit: Character) -> some View {
      let isLegal = self.viewModel.isLegal(digit)

      Button(action: {
        self.onKeyPressed(digit)
      }, label: {
        Text(String(digit))
          .font(.title2.weight(.bold).monospaced())
          .foregroundStyle(isLegal ? Color.text : Color.dimmed)
          .frame(maxWidth: .infinity, minHeight: self.keyMinimumHeight)
          .background(
            Color.text.opacity(isLegal ? 0.12 : 0.04),
            in: RoundedRectangle(cornerRadius: .cornerRadius.large)
          )
      })
      .buttonStyle(.press)
      .disabled(!isLegal)
      // Dimmed keys stay discoverable to VoiceOver as disabled — the shrinking alphabet must
      // survive non-visually (docs/06).
      .accessibilityLabel(Self.accessibilityLabel(for: digit))
      .accessibilityIdentifier("keypadKey-\(String(digit))")
    }

    private static func accessibilityLabel(for digit: Character) -> String {
      return String(format: String(localized: "Digit %1$@"), String(digit))
    }
  }
}
