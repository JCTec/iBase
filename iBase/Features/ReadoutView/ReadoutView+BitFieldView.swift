import SwiftUI

extension ReadoutView {
  /// Collapsing bit field: 16, 32, or 64 squares, never all 64 for a small value (docs/00, docs/06).
  struct BitFieldView: View {
    static let squareHeight: CGFloat = 22.0
    static let squareSpacing: CGFloat = 3.0
    static let bitsPerRow = 16

    let value: UInt64

    private var width: Int {
      return Radix.displayBitWidth(for: self.value)
    }

    private var bitsSet: Int {
      return self.value.nonzeroBitCount
    }

    /// Bit indices in reading order: most significant first, chunked into rows of 16.
    private var rows: [[Int]] {
      let descendingIndices = (0..<self.width).reversed().map { index in
        return index
      }

      return stride(from: 0, to: descendingIndices.count, by: Self.bitsPerRow).map { start in
        return Array(descendingIndices[start..<min(start + Self.bitsPerRow, descendingIndices.count)])
      }
    }

    private var squaresView: some View {
      VStack(spacing: Self.squareSpacing) {
        ForEach(Array(self.rows.enumerated()), id: \.offset) { _, row in
          HStack(spacing: Self.squareSpacing) {
            ForEach(row, id: \.self) { index in
              RoundedRectangle(cornerRadius: .cornerRadius.small)
                .fill(self.isSet(index) ? Color.accent : Color.text.opacity(0.08))
                .frame(maxWidth: .infinity)
                .frame(height: Self.squareHeight)
            }
          }
        }
      }
    }

    private var captionView: some View {
      HStack(spacing: .spacing.small) {
        Text("MSB · \(self.width - 1)")
          .contentTransition(.numericText())

        Spacer(minLength: .spacing.small)

        Text("\(self.bitsSet) BITS SET")
          .contentTransition(.numericText())

        Spacer(minLength: .spacing.small)

        Text("0 · LSB")
      }
      .font(.caption2.monospaced())
      .tracking(1.0)
      .foregroundStyle(Color.dimmed)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: .spacing.small) {
        self.squaresView
        self.captionView
      }
      .animation(.spring(response: 0.28, dampingFraction: 0.78), value: self.width)
      .animation(.spring(response: 0.22, dampingFraction: 0.8), value: self.value)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Bit field")
      .accessibilityValue("\(self.bitsSet) of \(self.width) bits set")
      .accessibilityIdentifier("bitFieldView")
    }

    private func isSet(_ index: Int) -> Bool {
      return (self.value >> UInt64(index)) & 1 == 1
    }
  }
}
