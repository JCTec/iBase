import Foundation

public enum IconSize {
  public static let small: CGFloat = 16
  public static let medium: CGFloat = 24
  public static let large: CGFloat = 32
  public static let xLarge: CGFloat = 48
  public static let xxLarge: CGFloat = 96
}

extension CGFloat {
  public static let iconSize = IconSize.self
}
