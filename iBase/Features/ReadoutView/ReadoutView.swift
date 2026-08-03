import SwiftUI
import SwiftData

/// Root screen. The value is already converted — there is nothing to submit (docs/00).
struct ReadoutView: View {
  static let baseReadoutFontSize: CGFloat = 92.0
  static let statusDotSize: CGFloat = 8.0
  static let caretWidth: CGFloat = 4.0
  static let caretHeightRatio: CGFloat = 0.62
  static let controlSize: CGFloat = 44.0
  static let readoutMinimumScaleFactor: CGFloat = 0.32
  static let sidebarMinimumWidth: CGFloat = 340.0

  @Binding var path: NavigationPath
  @Binding var currentValue: UInt64
  @Binding var selectedBase: Int

  @Environment(\.modelContext) private var modelContext
  #if !os(macOS)
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]

  @ScaledMetric private var readoutFontSize: CGFloat = ReadoutView.baseReadoutFontSize

  private var headerView: some View {
    HStack(spacing: .spacing.small) {
      Circle()
        .fill(Color.accent)
        .frame(width: Self.statusDotSize, height: Self.statusDotSize)

      Text("iBase")
        .font(.title3.weight(.semibold).monospaced())
        .foregroundStyle(Color.text)

      Spacer(minLength: .spacing.small)

      Text("RADIX 2–64")
        .font(.caption.monospaced())
        .tracking(1.2)
        .foregroundStyle(Color.dimmed)

      ActionButton(
        action: {
          self.openHistory()
        },
        imageName: "clock.arrow.circlepath",
        accessibilityLabel: "History",
        accessibilityIdentifier: "historyButton"
      )
      .symbolEffect(.bounce, value: self.entries.count)
    }
    .accessibilityElement(children: .contain)
  }

  private var inputCardView: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      HStack(spacing: .spacing.small) {
        Text("INPUT")
          .font(.caption.monospaced())
          .tracking(1.2)
          .foregroundStyle(Color.dimmed)

        Spacer(minLength: .spacing.small)

        self.baseMenuView
      }

      HStack(alignment: .center, spacing: .spacing.small) {
        Text(Radix.string(from: self.currentValue, base: self.selectedBase))
          .font(.system(size: self.readoutFontSize, weight: .bold, design: .monospaced))
          .lineLimit(1)
          .minimumScaleFactor(Self.readoutMinimumScaleFactor)
          .monospacedDigit()
          .contentTransition(.numericText())
          .foregroundStyle(Color.text)
          .accessibilityIdentifier("readoutValue")
          .accessibilityValue("base \(self.selectedBase)")

        RoundedRectangle(cornerRadius: .cornerRadius.small)
          .fill(Color.accent)
          .frame(width: Self.caretWidth, height: self.readoutFontSize * Self.caretHeightRatio)
          .accessibilityHidden(true)

        Spacer(minLength: 0)
      }

      self.bitFieldView
    }
    .padding(.spacing.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
    .overlay(
      RoundedRectangle(cornerRadius: .cornerRadius.medium)
        .stroke(Color.text.opacity(0.14), lineWidth: .borderWidth.standard)
    )
    .animation(.spring(response: 0.24, dampingFraction: 0.82), value: self.currentValue)
    .accessibilityElement(children: .contain)
  }

  private var bitFieldView: some View {
    BitFieldView(value: self.currentValue)
  }

  private var baseRowsView: some View {
    VStack(spacing: .spacing.small) {
      ForEach(Radix.displayBases, id: \.self) { base in
        BaseRowView(
          base: base,
          value: self.currentValue,
          isSelected: base == self.selectedBase,
          action: {
            self.selectBase(base)
          }
        )
      }
    }
  }

  private var baseMenuView: some View {
    Menu(content: {
      ForEach(Radix.entryBases, id: \.self) { base in
        Button(action: {
          self.selectBase(base)
        }, label: {
          Text("BASE \(base) · \(Radix.label(for: base))")
        })
        .accessibilityIdentifier("readoutBaseOption-\(base)")
      }
    }, label: {
      HStack(spacing: .spacing.small / 2.0) {
        Text("BASE \(self.selectedBase)")
          .font(.caption.monospaced())
          .tracking(1.2)
          .contentTransition(.numericText())

        Image(systemName: "chevron.down")
          .font(.caption2.weight(.bold))
      }
      .foregroundStyle(Color.accent)
    })
    .menuStyle(.borderlessButton)
    .fixedSize()
    .accessibilityLabel("Entry base")
    .accessibilityValue("base \(self.selectedBase)")
    .accessibilityIdentifier("readoutBaseMenu")
  }

  private var openEntryButtonView: some View {
    Button(action: {
      self.openEntry()
    }, label: {
      HStack(spacing: .spacing.small) {
        Image(systemName: "keyboard")
          .font(.body.weight(.bold))

        Text("ENTER VALUE")
          .font(.caption.monospaced())
          .tracking(1.6)
      }
      .foregroundStyle(Color.background)
      .frame(maxWidth: .infinity, minHeight: Self.controlSize)
      .background(Color.accent, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
    })
    .buttonStyle(.press)
    .accessibilityLabel("Enter a value")
    .accessibilityIdentifier("openEntryButton")
  }

  /// One layout that adapts — regular widths sit the readout and the base rows side by side,
  /// compact stacks them (docs/06). Both branches live in a *single* scroll view on purpose: a
  /// nested same-axis `ScrollView` for the rows renders correctly but stops hit-testing them, so
  /// base-row taps silently died on iPad.
  private var layoutView: some View {
    ScrollView {
      if self.isRegularWidth {
        HStack(alignment: .top, spacing: .spacing.large) {
          VStack(alignment: .leading, spacing: .spacing.medium) {
            self.headerView
            self.inputCardView
            self.openEntryButtonView
          }
          .frame(minWidth: Self.sidebarMinimumWidth)

          self.baseRowsView
        }
      } else {
        VStack(alignment: .leading, spacing: .spacing.medium) {
          self.headerView
          self.inputCardView
          self.openEntryButtonView
          self.baseRowsView
        }
      }
    }
  }

  var body: some View {
    self.layoutView
      .padding(.spacing.medium)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(Color.background)
      .toolbar(.hidden, for: .automatic)
      .task {
        self.seedShowcaseDataIfNeeded()
      }
  }

  /// `horizontalSizeClass` is iOS-only; on Mac every window is a regular-width layout.
  private var isRegularWidth: Bool {
    #if os(macOS)
    return true
    #else
    return self.horizontalSizeClass == .regular
    #endif
  }

  private func openEntry() {
    self.path.append(iBaseCoordinator.entry)
  }

  private func openHistory() {
    self.path.append(iBaseCoordinator.history)
  }

  private func selectBase(_ base: Int) {
    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
      self.selectedBase = base
    }
  }

  /// Guarded and idempotent — showcase runs only (docs/07).
  private func seedShowcaseDataIfNeeded() {
    guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.entries.isEmpty else { return }

    [
      HistoryEntry(value: 2026, enteredBase: 10),   // design reference value
      HistoryEntry(value: 126, enteredBase: 16),    // the design's 7E
      HistoryEntry(value: 255, enteredBase: 2),
      HistoryEntry(value: 4096, enteredBase: 8)
    ].forEach { entry in
      self.modelContext.insert(entry)
    }

    try? self.modelContext.save()
  }
}

// MARK: ActionButton

extension ReadoutView {
  /// The standard 44pt icon button (docs/06).
  struct ActionButton: View {
    let action: () -> Void
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3.weight(.bold))
          .foregroundStyle(Color.text)
          .frame(width: ReadoutView.controlSize, height: ReadoutView.controlSize)
          .background(Color.text.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.press)
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}
