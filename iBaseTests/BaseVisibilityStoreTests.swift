import XCTest
@testable import iBase

/// The point of the `UserDefault` wrapper is that a fresh device needs no initialisation logic:
/// an absent key *is* the default. These tests pin that, and that a user's choice survives as an
/// explicit `true`/`false` once made.
@MainActor
final class BaseVisibilityStoreTests: XCTestCase {
  /// A private suite per test, torn down afterwards, so no test can see another's writes — or the
  /// developer's real preferences. `setUpWithError` is a nonisolated override, so the suite is
  /// built here in the test body instead.
  private func makeDefaults() throws -> UserDefaults {
    let suiteName = "iBase.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

    self.addTeardownBlock {
      UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    return defaults
  }

  // MARK: First launch

  func testAFreshDeviceShowsTheDefaultBasesWithNothingWritten() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    XCTAssertEqual(store.visibleBases, BaseVisibilityStore.defaultVisibleBases)
    XCTAssertEqual(store.visibleDisplayBases, [2, 8, 10, 16, Radix.base64Base])
    XCTAssertTrue(store.isShowingDefaults)
  }

  func testNoKeysAreWrittenUntilTheUserChoosesSomething() throws {
    let defaults = try self.makeDefaults()
    _ = BaseVisibilityStore(store: defaults)

    let writtenKeys = Radix.displayBases.filter { base in
      return defaults.object(forKey: BaseVisibilityStore.storageKey(for: base)) != nil
    }

    XCTAssertTrue(writtenKeys.isEmpty, "a fresh device must not need a seeding pass")
  }

  func testTheDefaultSetIsBinaryOctalDecimalHexAndBase64() throws {
    XCTAssertTrue(BaseVisibilityStore.isVisibleByDefault(2))
    XCTAssertTrue(BaseVisibilityStore.isVisibleByDefault(8))
    XCTAssertTrue(BaseVisibilityStore.isVisibleByDefault(10))
    XCTAssertTrue(BaseVisibilityStore.isVisibleByDefault(16))
    XCTAssertTrue(BaseVisibilityStore.isVisibleByDefault(Radix.base64Base))

    XCTAssertFalse(BaseVisibilityStore.isVisibleByDefault(3))
    XCTAssertFalse(BaseVisibilityStore.isVisibleByDefault(36))
  }

  // MARK: Choosing

  func testEnablingABaseThatStartsHiddenMakesItVisible() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    store.setVisible(true, for: 36)

    XCTAssertTrue(store.isVisible(36))
    XCTAssertTrue(store.visibleDisplayBases.contains(36))
    XCTAssertFalse(store.isShowingDefaults)
  }

  func testDisablingADefaultBaseHidesIt() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    store.setVisible(false, for: 8)

    XCTAssertFalse(store.isVisible(8))
    XCTAssertFalse(store.visibleDisplayBases.contains(8))
  }

  func testAChoiceIsStoredExplicitlyAndSurvivesARelaunch() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)
    store.setVisible(false, for: 8)
    store.setVisible(true, for: 3)

    XCTAssertEqual(defaults.object(forKey: BaseVisibilityStore.storageKey(for: 8)) as? Bool, false)
    XCTAssertEqual(defaults.object(forKey: BaseVisibilityStore.storageKey(for: 3)) as? Bool, true)

    let relaunched = BaseVisibilityStore(store: defaults)

    XCTAssertFalse(relaunched.isVisible(8))
    XCTAssertTrue(relaunched.isVisible(3))
    XCTAssertTrue(relaunched.isVisible(16), "untouched bases still ride their default")
  }

  func testTogglingFlipsAndFlipsBack() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    store.toggleVisibility(of: 16)
    XCTAssertFalse(store.isVisible(16))

    store.toggleVisibility(of: 16)
    XCTAssertTrue(store.isVisible(16))
  }

  func testEveryBaseCanBeEnabled() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    Radix.displayBases.forEach { base in
      store.setVisible(true, for: base)
    }

    XCTAssertEqual(store.visibleDisplayBases, Radix.displayBases)
  }

  func testEveryBaseCanBeHidden() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)

    Radix.displayBases.forEach { base in
      store.setVisible(false, for: base)
    }

    XCTAssertTrue(store.visibleDisplayBases.isEmpty)
  }

  // MARK: Restoring

  func testRestoringDefaultsForgetsTheKeysRatherThanOverwritingThem() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)
    store.setVisible(false, for: 16)
    store.setVisible(true, for: 36)

    store.restoreDefaults()

    XCTAssertEqual(store.visibleBases, BaseVisibilityStore.defaultVisibleBases)
    XCTAssertTrue(store.isShowingDefaults)

    let writtenKeys = Radix.displayBases.filter { base in
      return defaults.object(forKey: BaseVisibilityStore.storageKey(for: base)) != nil
    }

    XCTAssertTrue(writtenKeys.isEmpty, "restoring must clear the keys so future defaults still apply")
  }

  // MARK: Row order

  func testVisibleBasesKeepCanonicalRowOrder() throws {
    let defaults = try self.makeDefaults()
    let store = BaseVisibilityStore(store: defaults)
    store.setVisible(true, for: 36)
    store.setVisible(true, for: 3)

    XCTAssertEqual(store.visibleDisplayBases, [2, 3, 8, 10, 16, 36, Radix.base64Base])
  }
}

/// The wrapper on its own — nil reads as the default, a write makes it explicit, a reset forgets it.
@MainActor
final class UserDefaultTests: XCTestCase {
  private func makeDefaults() throws -> UserDefaults {
    let suiteName = "iBase.tests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

    self.addTeardownBlock {
      UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    return defaults
  }

  func testAnAbsentKeyReadsAsTheDefault() throws {
    let defaults = try self.makeDefaults()
    let flag = UserDefault("missing", default: true, store: defaults)

    XCTAssertTrue(flag.wrappedValue)
    XCTAssertFalse(flag.isUserChosen)
  }

  func testWritingMakesTheValueExplicit() throws {
    let defaults = try self.makeDefaults()
    let flag = UserDefault("chosen", default: true, store: defaults)

    flag.wrappedValue = false

    XCTAssertFalse(flag.wrappedValue)
    XCTAssertTrue(flag.isUserChosen)
    XCTAssertEqual(defaults.object(forKey: "chosen") as? Bool, false)
  }

  func testWritingAValueEqualToTheDefaultStillCountsAsChosen() throws {
    let defaults = try self.makeDefaults()
    let flag = UserDefault("chosen", default: true, store: defaults)

    flag.wrappedValue = true

    XCTAssertTrue(flag.isUserChosen)
  }

  func testResettingForgetsTheKeyEntirely() throws {
    let defaults = try self.makeDefaults()
    let flag = UserDefault("chosen", default: true, store: defaults)
    flag.wrappedValue = false

    flag.reset()

    XCTAssertTrue(flag.wrappedValue)
    XCTAssertFalse(flag.isUserChosen)
    XCTAssertNil(defaults.object(forKey: "chosen"))
  }

  func testItCarriesNonBooleanValuesToo() throws {
    let defaults = try self.makeDefaults()
    let name = UserDefault("name", default: "iBase", store: defaults)

    XCTAssertEqual(name.wrappedValue, "iBase")

    name.wrappedValue = "Radix"

    XCTAssertEqual(name.wrappedValue, "Radix")
  }
}
