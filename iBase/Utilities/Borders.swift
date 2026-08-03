import Foundation

// MARK: CornerRadius
public enum CornerRadius {
  public static var small: CGFloat { 4 }
  public static var medium: CGFloat { 6 }
  public static var large: CGFloat { 8 }
}

// MARK: BorderWidth
public enum BorderWidth {
  public static var standard: CGFloat { 1 }
  public static var medium: CGFloat { 2 }
  public static var thick: CGFloat { 4 }
}

extension CGFloat {
  public static let cornerRadius = CornerRadius.self
  public static let borderWidth = BorderWidth.self
}
