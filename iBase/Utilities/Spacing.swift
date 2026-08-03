import Foundation

public enum Spacing {
  public static var baseline: CGFloat { Spacing.small }

  public static let small: CGFloat = 8.0
  public static let medium: CGFloat = 16.0
  public static let large: CGFloat = 24.0
  public static let xLarge: CGFloat = 32.0
}

extension CGFloat {
  public static let spacing = Spacing.self
}
