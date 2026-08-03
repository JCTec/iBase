import SwiftUI

/// Press-scale feedback for keypad keys, base rows, and icon buttons (docs/06).
///
/// Deviation from docs/02, flagged: the docs name this as the keypad's `fileprivate` helper, but
/// four views need identical press physics (keypad keys, commit, icon buttons, base rows). Keeping
/// it `fileprivate` would mean four copies of the same spring, so it lives once in `Utilities/`
/// alongside the other shared visual constants (docs/03, "shared visual constants").
public struct PressButtonStyle: ButtonStyle {
  public static let pressedScale: CGFloat = 0.93

  public init() {}

  public func makeBody(configuration: Configuration) -> some View {
    return configuration.label
      .scaleEffect(configuration.isPressed ? Self.pressedScale : 1.0)
      .animation(.spring(response: 0.18, dampingFraction: 0.72), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == PressButtonStyle {
  public static var press: PressButtonStyle {
    return PressButtonStyle()
  }
}
