import Foundation

#if os(iOS)
import UIKit
#endif

/// Impact haptics behind a wrapper that no-ops off iOS/iPadOS (docs/06).
///
/// `UIImpactFeedbackGenerator` is a UIKit type; on Mac every call here compiles to nothing so
/// feature views can fire feedback unconditionally instead of forking on platform.
/// The underlying generator is created lazily on first use so a view can hold one as a plain
/// `let` stored property without touching the main actor at initialisation time.
public final class HapticGenerator: Sendable {

  public enum Style: Sendable {
    case heavy
    case rigid
    case light

    #if os(iOS)
    fileprivate var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
      switch self {
        case .heavy:
          return .heavy
        case .rigid:
          return .rigid
        case .light:
          return .light
      }
    }
    #endif
  }

  private let style: Style

  #if os(iOS)
  @MainActor private var generator: UIImpactFeedbackGenerator?
  #endif

  public init(style: Style) {
    self.style = style
  }

  /// Warms the Taptic Engine ahead of an interaction that is about to happen.
  @MainActor
  public func prepare() {
    #if os(iOS)
    self.makeGeneratorIfNeeded().prepare()
    #endif
  }

  /// Fires the impact. Silent no-op on macOS — dead means dead, everywhere (docs/06).
  @MainActor
  public func impactOccurred() {
    #if os(iOS)
    self.makeGeneratorIfNeeded().impactOccurred()
    #endif
  }

  #if os(iOS)
  @MainActor
  private func makeGeneratorIfNeeded() -> UIImpactFeedbackGenerator {
    if let generator = self.generator {
      return generator
    }

    let generator = UIImpactFeedbackGenerator(style: self.style.feedbackStyle)
    self.generator = generator
    return generator
  }
  #endif
}
