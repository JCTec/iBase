import SwiftUI
import SwiftData

/// The immersive typing surface. Replaces the template's editor form but keeps its guarantees:
/// one throwing parse backs both the live preview and `canCommit`, so they can never disagree
/// (docs/04 §4, docs/06).
struct EntryView: View {
  static let keyMinimumHeight: CGFloat = 56.0
  static let regularKeyMinimumHeight: CGFloat = 64.0
  static let keyMinimumWidth: CGFloat = 56.0
  static let regularKeyMinimumWidth: CGFloat = 72.0
  static let controlSize: CGFloat = 44.0
  static let baseTypingFontSize: CGFloat = 56.0
  static let caretWidth: CGFloat = 4.0
  static let caretHeightRatio: CGFloat = 0.72
  static let typingMinimumScaleFactor: CGFloat = 0.4
  static let quickConversionMinimumScaleFactor: CGFloat = 0.5
  static let pulseScale: CGFloat = 1.02
  static let pulseSettleDelay: TimeInterval = 0.14

  @Binding var path: NavigationPath
  @Binding var currentValue: UInt64
  /// Flagged addition to the docs/04 §2 signature. `viewModel: .init(base: self.selectedBase)` on
  /// its own hands the keypad a *stale* base: SwiftUI does not re-register the
  /// `navigationDestination` builder when the root's `selectedBase` changes, so picking hex on the
  /// readout and opening the keypad still produced a base-10 keypad. A binding is read live even
  /// from a stale closure, so the base is re-synced in `.task` and written back on change — which
  /// is also what docs/04 §2 asks for in principle ("screens receive them as `@Binding`s").
  @Binding var selectedBase: Int

  @StateObject var viewModel: ViewModel

  @Environment(\.modelContext) private var modelContext

  @State private var isPulsing = false
  /// Hardware keyboards only deliver key presses to a focused view, so the typing surface claims
  /// focus on appear and takes it back after every on-screen tap (which moves focus to the button).
  @FocusState private var isKeyboardFocused: Bool

  @ScaledMetric private var typingFontSize: CGFloat = EntryView.baseTypingFontSize

  // Heavy for the primary interaction, rigid for edits — no-ops on Mac (docs/06).
  private let keyGenerator = HapticGenerator(style: .heavy)
  private let editGenerator = HapticGenerator(style: .rigid)

  init(
    path: Binding<NavigationPath>,
    currentValue: Binding<UInt64>,
    selectedBase: Binding<Int>,
    viewModel: ViewModel
  ) {
    self._path = path
    self._currentValue = currentValue
    self._selectedBase = selectedBase
    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  private var headerView: some View {
    HStack(spacing: .spacing.small) {
      ActionButton(
        action: {
          self.close()
        },
        imageName: "chevron.backward",
        accessibilityLabel: "Back",
        accessibilityIdentifier: "backButton"
      )

      Text("BACK")
        .font(.caption.monospaced())
        .tracking(1.6)
        .foregroundStyle(Color.dimmed)

      Spacer(minLength: .spacing.small)

      self.baseMenuView
    }
    .accessibilityElement(children: .contain)
  }

  private var typingCardView: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      Text("TYPING")
        .font(.caption.monospaced())
        .tracking(1.2)
        .foregroundStyle(Color.dimmed)

      HStack(alignment: .center, spacing: .spacing.small) {
        Text(self.viewModel.digits)
          .font(.system(size: self.typingFontSize, weight: .bold, design: .monospaced))
          .lineLimit(1)
          .minimumScaleFactor(Self.typingMinimumScaleFactor)
          .monospacedDigit()
          .contentTransition(.numericText())
          .foregroundStyle(Color.text)
          .accessibilityIdentifier("typingValue")
          .accessibilityLabel("Typed digits")
          .accessibilityValue(self.typedDigitsAccessibilityValue)

        RoundedRectangle(cornerRadius: .cornerRadius.small)
          .fill(Color.accent)
          .frame(width: Self.caretWidth, height: self.typingFontSize * Self.caretHeightRatio)
          .accessibilityHidden(true)

        Spacer(minLength: 0)
      }

      Text(self.previewText)
        .font(.callout.monospaced())
        .monospacedDigit()
        .contentTransition(.numericText())
        .foregroundStyle(self.viewModel.previewValue == nil ? Color.dimmed : Color.accent)
        .accessibilityIdentifier("previewLabel")
        // The visible text is prose and therefore translated; the value is the number alone, which
        // is not. VoiceOver gains a cleaner reading and the UI journey gains an assertion that
        // survives every language.
        .accessibilityLabel("Decimal preview")
        .accessibilityValue(self.previewAccessibilityValue)
    }
    .padding(.spacing.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
    .overlay(
      RoundedRectangle(cornerRadius: .cornerRadius.medium)
        .stroke(Color.accent.opacity(0.4), lineWidth: .borderWidth.standard)
    )
    .scaleEffect(self.isPulsing ? Self.pulseScale : 1.0)
    .animation(.spring(response: 0.22, dampingFraction: 0.8), value: self.viewModel.digits)
    .accessibilityElement(children: .contain)
  }

  private var quickConversionsView: some View {
    HStack(spacing: .spacing.small) {
      ForEach(Self.quickConversionBases, id: \.self) { base in
        // Verbatim: a radix label next to its digits is notation end to end (docs/03, `Radix.label`).
        Text(verbatim: "\(Radix.label(for: base)) \(Radix.string(from: self.viewModel.previewValue ?? 0, base: base))")
          .font(.caption.monospaced())
          .monospacedDigit()
          .contentTransition(.numericText())
          .foregroundStyle(Color.dimmed)
          .lineLimit(1)
          .minimumScaleFactor(Self.quickConversionMinimumScaleFactor)
          .padding(.horizontal, .spacing.small)
          .padding(.vertical, .spacing.small / 2.0)
          .frame(maxWidth: .infinity)
          .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius.medium)
              .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
          )
          .accessibilityIdentifier("quickConversion-\(base)")
      }
    }
  }

  private var keypadView: some View {
    KeypadView(
      viewModel: self.viewModel,
      onKeyPressed: { digit in
        self.appendDigit(digit)
      }
    )
  }

  private var controlsView: some View {
    HStack(spacing: .spacing.medium) {
      ActionButton(
        action: {
          self.deleteLastDigit()
        },
        imageName: "delete.left",
        accessibilityLabel: "Delete last digit",
        accessibilityIdentifier: "deleteButton"
      )
      .disabled(self.viewModel.digits.isEmpty)

      Button(action: {
        self.commit()
      }, label: {
        Text("COMMIT")
          .font(.caption.monospaced())
          .tracking(1.6)
          .foregroundStyle(self.viewModel.canCommit ? Color.background : Color.dimmed)
          .frame(maxWidth: .infinity, minHeight: Self.controlSize)
          .background(
            self.viewModel.canCommit ? Color.accent : Color.text.opacity(0.08),
            in: RoundedRectangle(cornerRadius: .cornerRadius.large)
          )
      })
      .buttonStyle(.press)
      .disabled(!self.viewModel.canCommit)
      .accessibilityLabel("Commit value")
      .accessibilityIdentifier("commitButton")
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
        .accessibilityIdentifier("entryBaseOption-\(base)")
      }
    }, label: {
      HStack(spacing: .spacing.small / 2.0) {
        Text("ENTRY · BASE \(self.viewModel.base)")
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
    .accessibilityValue(self.baseAccessibilityValue)
    .accessibilityIdentifier("entryBaseMenu")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      self.headerView
      self.typingCardView
      self.quickConversionsView

      ScrollView {
        self.keypadView
      }

      self.controlsView
    }
    .padding(.spacing.medium)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color.background)
    .toolbar(.hidden, for: .automatic)
    .focusable()
    .focusEffectDisabled()
    .focused(self.$isKeyboardFocused)
    .onKeyPress(action: { keyPress in
      return self.handleKeyPress(keyPress)
    })
    .alert(
      "Could not save",
      isPresented: Binding(
        get: {
          return self.viewModel.errorMessage != nil
        },
        set: { isPresented in
          if !isPresented {
            self.viewModel.errorMessage = nil
          }
        }
      ),
      actions: {
        Button("OK", role: .cancel, action: {
          self.viewModel.errorMessage = nil
        })
      },
      message: {
        Text(self.viewModel.errorMessage ?? "")
      }
    )
    .task {
      self.viewModel.base = self.selectedBase
      self.keyGenerator.prepare()
      self.isKeyboardFocused = true
    }
  }

  // MARK: Localized text

  private var previewText: String {
    guard let value = self.viewModel.previewValue else {
      return String(localized: "AWAITING INPUT")
    }
    // The ₁₀ subscript is the decimal-base notation, not punctuation — it stays in every language.
    return String(format: String(localized: "= %1$llu₁₀ so far"), value)
  }

  private var typedDigitsAccessibilityValue: String {
    guard !self.viewModel.digits.isEmpty else {
      return String(localized: "empty", comment: "Accessibility value when nothing has been typed yet")
    }
    return self.viewModel.digits // digits are notation, never translated
  }

  private var previewAccessibilityValue: String {
    guard let value = self.viewModel.previewValue else {
      return String(localized: "awaiting input", comment: "Accessibility value of the decimal preview before any digit is typed")
    }
    return String(value) // the decimal number alone — no prose, so it reads the same in any language
  }

  private var baseAccessibilityValue: String {
    return String(format: String(localized: "base %1$lld"), self.viewModel.base)
  }

  private func appendDigit(_ digit: Character) {
    guard self.viewModel.isLegal(digit) else { return } // dead means dead: no haptic, no motion

    self.keyGenerator.impactOccurred()
    self.viewModel.append(digit)
    self.isKeyboardFocused = true
  }

  private func deleteLastDigit() {
    guard !self.viewModel.digits.isEmpty else { return }

    self.editGenerator.impactOccurred()
    self.viewModel.deleteLastDigit()
    self.isKeyboardFocused = true
  }

  private func selectBase(_ base: Int) {
    self.editGenerator.impactOccurred()
    self.isKeyboardFocused = true

    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
      self.viewModel.base = base
      self.selectedBase = base // one workspace base, shared with the readout (docs/00)
    }
  }

  private func commit() {
    do {
      let entry = try self.viewModel.commit(in: self.modelContext)

      self.currentValue = entry.value
      self.playCommitFeedback()
      self.close()
    } catch {
      self.viewModel.errorMessage = error.localizedDescription
    }
  }

  private func close() {
    if self.path.count > 0 {
      self.path.removeLast()
    }
  }

  private func playCommitFeedback() {
    self.keyGenerator.impactOccurred()

    withAnimation(.spring(response: 0.18, dampingFraction: 0.68)) {
      self.isPulsing = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + Self.pulseSettleDelay) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.86)) {
        self.isPulsing = false
      }
    }
  }

  /// Hardware keyboard (iPad/Mac). This method only *translates* — every decision about what is
  /// allowed comes from `ViewModel.command(for:)`, the same guards the on-screen keypad uses, so
  /// the two input paths cannot drift apart (docs/06).
  private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
    guard let input = ViewModel.KeyInput(keyPress) else {
      return .ignored
    }

    switch self.viewModel.command(for: input) {
      case .append(let digit):
        self.appendDigit(digit)
        return .handled
      case .delete:
        self.deleteLastDigit()
        return .handled
      case .commit:
        self.commit()
        return .handled
      case .cancel:
        self.close()
        return .handled
      case .ignore:
        // Swallowed, not passed on: an illegal digit is a no-op, never a system error sound.
        return .ignored
    }
  }
}

// MARK: Constants

extension EntryView {
  /// The design's three at-a-glance chips under the typing card.
  static let quickConversionBases = [2, 8, 36]
}

// MARK: ActionButton

extension EntryView {
  /// The standard 44pt icon button (docs/06).
  struct ActionButton: View {
    let action: () -> Void
    let imageName: String
    /// A `LocalizedStringResource`, not a `String`: a stored `String` would be resolved at the call
    /// site and reach the modifier already flattened, so the literal would never be extracted.
    let accessibilityLabel: LocalizedStringResource
    /// A `String`, and deliberately so — identifiers are test hooks, never translated.
    let accessibilityIdentifier: String

    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3.weight(.bold))
          .foregroundStyle(Color.text)
          .frame(width: EntryView.controlSize, height: EntryView.controlSize)
          .background(Color.text.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.press)
      .accessibilityLabel(Text(self.accessibilityLabel))
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}

// MARK: InputError

extension EntryView {
  enum InputError: LocalizedError, Equatable {
    case illegalDigit(Character)
    case overflow

    var errorDescription: String? {
      switch self {
        case .illegalDigit(let digit):
          return String(format: String(localized: "%1$@ is not a digit in this base."), String(digit))
        case .overflow:
          return String(localized: "Value exceeds the 64-bit maximum.")
      }
    }
  }
}

// MARK: Keyboard input

extension EntryView.ViewModel {
  /// A keystroke, reduced to the only four things this screen cares about.
  enum KeyInput: Equatable {
    case character(Character)
    case delete
    case submit
    case cancel

    init?(_ keyPress: KeyPress) {
      switch keyPress.key {
        case .delete, .deleteForward:
          self = .delete
        case .return:
          self = .submit
        case .escape:
          self = .cancel
        default:
          guard let character = keyPress.characters.first else { return nil }
          self = .character(character)
      }
    }
  }

  enum KeyCommand: Equatable {
    case append(Character)
    case delete
    case commit
    case cancel
    case ignore
  }
}

// MARK: ViewModel

extension EntryView {
  /// The one view model iBase earns: per-digit legality, overflow guarding, commit-to-history
  /// (docs/01, docs/04 §4).
  final class ViewModel: ObservableObject {
    @Published var digits: String = ""
    @Published var base: Int
    @Published var errorMessage: String?

    init(base: Int = HistoryEntry.defaultBase) {
      self.base = base
    }

    var canCommit: Bool {
      return !self.digits.isEmpty
    }

    /// Live decimal preview — the design's "= 126₁₀ so far".
    var previewValue: UInt64? {
      return try? Radix.value(from: self.digits, base: self.base)
    }

    func isLegal(_ digit: Character) -> Bool {
      return Radix.legalDigits(for: self.base).contains(digit)
    }

    /// Guarded no-op on illegal digit or 64-bit overflow — the keypad dims, it never errors.
    func append(_ digit: Character) {
      guard self.isLegal(digit) else { return }

      let candidate = self.digits + String(digit)
      guard (try? Radix.value(from: candidate, base: self.base)) != nil else { return } // overflow

      self.digits = candidate
    }

    func deleteLastDigit() {
      guard !self.digits.isEmpty else { return }
      self.digits.removeLast()
    }

    /// What a keystroke should do. Pure and synchronous, so the hardware-keyboard policy is unit
    /// tested on every platform — including the ones where XCUITest cannot drive a real keyboard.
    func command(for input: KeyInput) -> KeyCommand {
      switch input {
        case .delete:
          return self.digits.isEmpty ? .ignore : .delete
        case .submit:
          return self.canCommit ? .commit : .ignore
        case .cancel:
          return .cancel
        case .character(let character):
          return self.command(forTyped: character)
      }
    }

    /// Typing folds to the uppercase alphabet the app uses everywhere, then runs the *same* two
    /// guards as `append(_:)`: legal in this base, and still parseable afterwards.
    private func command(forTyped character: Character) -> KeyCommand {
      guard let digit = character.uppercased().first, self.isLegal(digit) else {
        return .ignore
      }

      let candidate = self.digits + String(digit)
      guard (try? Radix.value(from: candidate, base: self.base)) != nil else {
        return .ignore // overflow
      }

      return .append(digit)
    }

    /// Throwing, centralized validation + persistence — the editor pattern's shape, applied to entry.
    @discardableResult
    func commit(in modelContext: ModelContext) throws -> HistoryEntry {
      let value = try Radix.value(from: self.digits, base: self.base)
      let entry = HistoryEntry(value: value, enteredBase: self.base)

      modelContext.insert(entry)
      try modelContext.save()
      return entry
    }
  }
}

// MARK: Previews

@MainActor
private struct _EntryViewPreview: View {
  @State var path = NavigationPath()
  @State var currentValue: UInt64 = 2026
  @State var selectedBase: Int

  let base: Int
  let digits: String

  init(base: Int, digits: String) {
    self.base = base
    self.digits = digits
    self._selectedBase = State(initialValue: base)
  }

  var body: some View {
    EntryView(
      path: self.$path,
      currentValue: self.$currentValue,
      selectedBase: self.$selectedBase,
      viewModel: {
        let viewModel = EntryView.ViewModel(base: self.base)
        viewModel.digits = self.digits
        return viewModel
      }()
    )
    .modelContainer(for: HistoryEntry.self, inMemory: true)
  }
}

#Preview("Entry · base 16") {
  _EntryViewPreview(base: 16, digits: "7E")
    .preferredColorScheme(.dark)
}

#Preview("Entry · base 2 (34 dead keys)") {
  _EntryViewPreview(base: 2, digits: "1111110")
    .preferredColorScheme(.dark)
}

#Preview("Entry · base 36 (none dead)") {
  _EntryViewPreview(base: 36, digits: "3I")
    .preferredColorScheme(.dark)
}
