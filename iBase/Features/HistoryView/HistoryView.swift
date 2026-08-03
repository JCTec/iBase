import SwiftUI
import SwiftData

/// Past commits. Persistence *is* conversion history (docs/00) — reads `@Query` directly, no view
/// model, no fetch-controller ceremony (docs/04 §3).
struct HistoryView: View {
  static let rowMinimumHeight: CGFloat = 56.0
  static let controlSize: CGFloat = 44.0
  static let searchThreshold = 10
  static let rowMinimumScaleFactor: CGFloat = 0.5

  @Binding var path: NavigationPath
  @Binding var currentValue: UInt64
  @Binding var selectedBase: Int

  @Environment(\.modelContext) private var modelContext
  @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]

  @State private var searchQuery = ""
  @State private var sortOption: SortOption = .newest
  @State private var isShowingClearConfirmation = false
  @State private var entryPendingDeletion: HistoryEntry?

  private var controlsView: some View {
    HStack(spacing: .spacing.small) {
      Text(verbatim: "\(self.entries.count) ENTRIES")
        .font(.caption.monospaced())
        .tracking(1.2)
        .monospacedDigit()
        .contentTransition(.numericText())
        .foregroundStyle(Color.dimmed)

      Spacer(minLength: .spacing.small)

      Menu(content: {
        Picker("Sort", selection: self.$sortOption) {
          ForEach(SortOption.allCases) { option in
            Label(option.rawValue, systemImage: option.systemImageName)
              .tag(option)
          }
        }
        .pickerStyle(.inline)

        Divider()

        Button(role: .destructive, action: {
          self.isShowingClearConfirmation = true
        }, label: {
          Label("Clear History", systemImage: "trash")
        })
        .accessibilityIdentifier("clearHistoryButton")
      }, label: {
        Image(systemName: "ellipsis.circle")
          .font(.title3.weight(.bold))
          .foregroundStyle(Color.text)
          .frame(width: Self.controlSize, height: Self.controlSize)
      })
      .menuStyle(.borderlessButton)
      .fixedSize()
      .accessibilityLabel("History options")
      .accessibilityIdentifier("historyOptionsMenu")
    }
    .padding(.horizontal, .spacing.medium)
    .background(.ultraThinMaterial)
    .overlay(
      RoundedRectangle(cornerRadius: .cornerRadius.medium)
        .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
    )
    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius.medium))
    .accessibilityElement(children: .contain)
  }

  private var listView: some View {
    List {
      ForEach(self.visibleEntries) { entry in
        self.rowView(for: entry)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
  }

  @ViewBuilder
  private var contentView: some View {
    if self.entries.isEmpty {
      ContentUnavailableView(
        "No conversions yet",
        systemImage: "number.square",
        description: Text("Commit a value from the keypad and it lands here.")
      )
      // Combine so the state reads as one element and exposes one identifier — otherwise the
      // identifier lands on each of the view's three children.
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("emptyHistoryView")
    } else if self.visibleEntries.isEmpty {
      ContentUnavailableView.search(text: self.searchQuery)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("noSearchResultsView")
    } else {
      self.listView
    }
  }

  @ViewBuilder
  private var searchableContentView: some View {
    // Progressive disclosure: search only earns its chrome past the threshold (docs/06).
    if self.shouldShowSearch {
      self.contentView
        .searchable(text: self.$searchQuery, prompt: "Filter history")
    } else {
      self.contentView
    }
  }

  var body: some View {
    VStack(spacing: .spacing.medium) {
      // Controls render only when there is data (docs/01, docs/06).
      if !self.entries.isEmpty {
        self.controlsView
          .frame(height: Self.controlSize)
          .padding(.horizontal, .spacing.medium)
      }

      self.searchableContentView
    }
    .padding(.top, .spacing.medium)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.background)
    .onChange(of: self.shouldShowSearch) { _, isShowing in
      if !isShowing {
        self.searchQuery = ""
      }
    }
    .confirmationDialog(
      "Delete this entry?",
      isPresented: Binding(
        get: {
          return self.entryPendingDeletion != nil
        },
        set: { isPresented in
          if !isPresented {
            self.entryPendingDeletion = nil
          }
        }
      ),
      titleVisibility: .visible,
      actions: {
        Button("Delete", role: .destructive, action: {
          self.deletePendingEntry()
        })
        .accessibilityIdentifier("confirmDeleteButton")

        Button("Cancel", role: .cancel, action: {
          self.entryPendingDeletion = nil
        })
      }
    )
    .confirmationDialog(
      "Clear all history?",
      isPresented: self.$isShowingClearConfirmation,
      titleVisibility: .visible,
      actions: {
        Button("Clear History", role: .destructive, action: {
          self.clearHistory()
        })
        .accessibilityIdentifier("confirmClearHistoryButton")

        Button("Cancel", role: .cancel, action: {})
      }
    )
  }

  private var shouldShowSearch: Bool {
    return self.entries.count >= Self.searchThreshold
  }

  private var visibleEntries: [HistoryEntry] {
    let query = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    let filtered = query.isEmpty ? self.entries : self.entries.filter { entry in
      return entry.enteredDigits.contains(query) || String(entry.value).contains(query)
    }

    return filtered.sorted(by: self.sortOption.areInIncreasingOrder)
  }

  @ViewBuilder
  private func rowView(for entry: HistoryEntry) -> some View {
    // Verbatim, never localized: an instrument panel shows 4096, not "4,096".
    let decimalValue = String(entry.value)

    Button(action: {
      self.loadEntry(entry)
    }, label: {
      HStack(alignment: .center, spacing: .spacing.medium) {
        VStack(alignment: .leading, spacing: .spacing.small / 2.0) {
          Text(entry.enteredDigits)
            .font(.title3.weight(.bold).monospaced())
            .monospacedDigit()
            .foregroundStyle(Color.text)
            .lineLimit(1)
            .minimumScaleFactor(Self.rowMinimumScaleFactor)

          Text("\(Radix.label(for: entry.enteredBase)) · BASE \(entry.enteredBase)")
            .font(.caption2.monospaced())
            .tracking(1.0)
            .foregroundStyle(Color.dimmed)
        }

        Spacer(minLength: .spacing.small)

        Text(decimalValue)
          .font(.body.monospaced())
          .monospacedDigit()
          .foregroundStyle(Color.accent)
          .lineLimit(1)
          .minimumScaleFactor(Self.rowMinimumScaleFactor)
      }
      .padding(.horizontal, .spacing.medium)
      .padding(.vertical, .spacing.small)
      .frame(minHeight: Self.rowMinimumHeight)
      .frame(maxWidth: .infinity)
      .background(Color.panel, in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
      .overlay(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
      )
    })
    .buttonStyle(.press)
    .listRowInsets(EdgeInsets(top: .spacing.small / 2.0, leading: .spacing.medium, bottom: .spacing.small / 2.0, trailing: .spacing.medium))
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entry.enteredDigits) in base \(entry.enteredBase)")
    .accessibilityValue(decimalValue)
    // Combining collapses the button, so the trait is restored explicitly.
    .accessibilityAddTraits(.isButton)
    .accessibilityIdentifier("historyEntry-\(entry.enteredDigits)")
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      self.deleteButton(for: entry)
    }
    .contextMenu {
      self.deleteButton(for: entry)
    }
  }

  private func deleteButton(for entry: HistoryEntry) -> some View {
    return Button(role: .destructive, action: {
      self.entryPendingDeletion = entry
    }, label: {
      Label("Delete", systemImage: "trash")
    })
    .accessibilityIdentifier("deleteEntryButton-\(entry.enteredDigits)")
  }

  private func loadEntry(_ entry: HistoryEntry) {
    self.currentValue = entry.value
    self.selectedBase = entry.enteredBase
    self.path = NavigationPath() // pop to root
  }

  private func deletePendingEntry() {
    guard let entry = self.entryPendingDeletion else { return }

    self.modelContext.delete(entry)
    try? self.modelContext.save()
    self.entryPendingDeletion = nil
  }

  private func clearHistory() {
    self.entries.forEach { entry in
      self.modelContext.delete(entry)
    }

    try? self.modelContext.save()
    self.searchQuery = ""
  }
}

// MARK: SortOption

extension HistoryView {
  enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case largest = "Largest"

    var id: Self { self }

    var systemImageName: String {
      switch self {
        case .newest:
          return "arrow.down.circle"
        case .oldest:
          return "arrow.up.circle"
        case .largest:
          return "arrow.up.arrow.down.circle"
      }
    }

    func areInIncreasingOrder(_ lhs: HistoryEntry, _ rhs: HistoryEntry) -> Bool {
      switch self {
        case .newest:
          return lhs.createdAt > rhs.createdAt
        case .oldest:
          return lhs.createdAt < rhs.createdAt
        case .largest:
          return lhs.value > rhs.value
      }
    }
  }
}
