# 04 — Architecture

Four pillars: a thin `@main` entry, typed navigation via a coordinator enum, SwiftData models that own their business logic, and MVVM only where complexity earns it.

## 1. App entry — `MyAppApp.swift`

The entry point builds the `ModelContainer`, switches to an in-memory store under test/showcase launch flags, and hosts App Intents.

```swift
import AppIntents
import SwiftUI
import SwiftData

@main
struct MyAppApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Item.self,
    ])
    let launchArguments = ProcessInfo.processInfo.arguments
    let usesTemporaryStore = launchArguments.contains("-UITesting") || launchArguments.contains("-ShowcaseData")

    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: usesTemporaryStore)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      MyAppNavigationView()
    }
    .modelContainer(sharedModelContainer)
  }
}
```

## 2. Typed navigation — coordinator enum + `NavigationStack`

No stringly-typed navigation. One `Hashable` enum lists every route; the root view owns a `NavigationPath` and passes it down as a `@Binding` so any screen can push (`path.append(route)`) or pop (`path.removeLast()`).

```swift
import SwiftUI

enum MyAppCoordinator: Hashable {
  case createItem
  case editItem(Item)
  case viewItem(Item)
}

struct MyAppNavigationView: View {
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: self.$path) {
      ItemsListView(path: self.$path)
        .navigationDestination(for: MyAppCoordinator.self) { route in
          switch route {
            case .createItem:
              EditItemView(path: self.$path, viewModel: .init())
                .navigationBarTitle("Create Item")
            case .editItem(let item):
              EditItemView(path: self.$path, viewModel: .init(item: item, isEditing: true))
                .navigationBarTitle("Edit Item")
            case .viewItem(let item):
              ItemView(path: self.$path, item: item)
                .navigationBarBackButtonHidden(true)
          }
        }
    }
  }
}
```

Conventions: pop-to-root is `self.path = NavigationPath()`; safe pop is `if self.path.count > 0 { self.path.removeLast() }`; immersive detail screens hide the back button and provide their own close control.

## 3. Model layer — SwiftData, logic on the model

`@Model` classes own their business rules as methods and expose derived UI values as `@Transient` computed properties. Design CloudKit-ready: defaults on every stored property.

```swift
import SwiftUI
import SwiftData

@Model
final class Item {
  static let defaultIncrement = 1

  var id: UUID = UUID()
  var name: String = ""
  var value: Int = 0

  @Transient var canReduceValue: Bool {
    return (self.value - Self.defaultIncrement) >= 0
  }

  init(id: UUID = UUID(), name: String, value: Int) {
    self.id = id
    self.name = name
    self.value = value
  }

  init() {
    self.id = UUID()
    self.name = ""
    self.value = 0
  }

  // Business logic lives here — guarded, no-op on invalid input.
  func incrementValue() {
    self.value += Self.defaultIncrement
  }

  func resetValue() {
    self.value = 0
  }
}

extension Item: Hashable, Equatable {
  static func == (lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
```

Rules: a `static let default…` for every non-trivial default; identity-based `Hashable`/`Equatable` on `id`; mutations are guarded methods (`guard … else { return }`), never raw property writes from views when an invariant exists; a parameterless convenience `init()` for drafts.

Views read `@Query` directly and derive filtered/sorted output in a computed property (`visibleItems`) — no fetch-controller ceremony.

## 4. MVVM — only where earned

Simple screens (a counter, a detail view) mutate the model directly. Editor/form screens get a `final class ViewModel: ObservableObject`, declared **inside an extension of the view, in the same file**:

```swift
extension EditItemView {
  enum ValidationError: LocalizedError, Equatable {
    case emptyName

    var errorDescription: String? {
      switch self {
        case .emptyName:
          return "Name is required."
      }
    }
  }

  struct ValidatedValues: Equatable {
    let name: String
    let value: Int
  }

  final class ViewModel: ObservableObject {
    @Published var name: String
    @Published var value: Int
    @Published var errorMessage: String?

    let item: Item?

    init(item: Item = Item(), isEditing: Bool = false) {
      self.item = isEditing ? item : nil
      self.name = item.name
      self.value = item.value
    }

    var isEditing: Bool {
      return self.item != nil
    }

    var validationMessage: String? {
      do {
        _ = try self.validatedValues()
        return nil
      } catch {
        return error.localizedDescription
      }
    }

    var canSave: Bool {
      return self.validationMessage == nil
    }

    func validatedValues() throws -> ValidatedValues {
      let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !trimmedName.isEmpty else {
        throw ValidationError.emptyName
      }

      return ValidatedValues(name: trimmedName, value: self.value)
    }

    @discardableResult
    func save(in modelContext: ModelContext) throws -> Item {
      let values = try self.validatedValues()
      let item = self.item ?? Item()

      item.name = values.name
      item.value = values.value

      if self.item == nil {
        modelContext.insert(item)
      }

      try modelContext.save()
      return item
    }

    func delete(in modelContext: ModelContext) throws {
      guard let item = self.item else { return }
      modelContext.delete(item)
      try modelContext.save()
    }
  }
}
```

The pattern's signatures matter:

- **Create and edit share one view.** `item == nil` means creating; `isEditing` drives UI differences (delete button, title).
- **Validation is throwing and centralized** in `validatedValues()`; `validationMessage`/`canSave` derive from it so the Save button and the inline error can never disagree.
- **The view model receives `ModelContext` as a parameter** (`save(in:)`, `delete(in:)`) — it never stores it.
- The view holds it as `@StateObject var viewModel: ViewModel`, injected via the coordinator.
- View wraps calls in do/catch and routes failures to `viewModel.errorMessage` → `.alert`.
