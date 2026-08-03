#!/usr/bin/env swift

//  generate_appstore_assets.swift
//
//  Layer 2 of the screenshot pipeline (docs/08): composition.
//
//  Layer 1 is `AppStoreScreenshotUITests`, which captures raw device screenshots. This script
//  frames those captures into every App Store dimension and writes them to `AppStoreAssets/` in
//  per-device folders. Marketing copy lives here, not in a design file, so localized or restyled
//  variants regenerate with the artwork.
//
//  Usage, from the repo root:
//
//    # 1. capture (writes 01-readout.png, 02-entry.png, 03-history.png)
//    TEST_RUNNER_APPSTORE_SCREENSHOT_DIR="$PWD/AppStoreAssets/captures" \
//      xcodebuild test -project iBase.xcodeproj -scheme iBase \
//      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
//      -only-testing:iBaseUITests/AppStoreScreenshotUITests
//
//    # 2. compose
//    swift Scripts/generate_appstore_assets.swift
//
//  Options:
//    --input  <dir>   captures directory   (default: AppStoreAssets/captures)
//    --output <dir>   composed output      (default: AppStoreAssets)
//
//  Zero dependencies — AppKit does the drawing (docs/01).

import AppKit
import Foundation

// MARK: Palette — the same five tokens as Assets.xcassets/Colors (docs/05)

enum Palette {
  static let background = NSColor(srgbRed: 0x0B / 255.0, green: 0x0B / 255.0, blue: 0x0C / 255.0, alpha: 1.0)
  static let panel = NSColor(srgbRed: 0x13 / 255.0, green: 0x13 / 255.0, blue: 0x16 / 255.0, alpha: 1.0)
  static let text = NSColor(srgbRed: 0xF2 / 255.0, green: 0xF2 / 255.0, blue: 0xF0 / 255.0, alpha: 1.0)
  static let accent = NSColor(srgbRed: 0x7E / 255.0, green: 0xD3 / 255.0, blue: 0x21 / 255.0, alpha: 1.0)
  static var dimmed: NSColor { return Palette.text.withAlphaComponent(0.4) }
}

// MARK: Specs

struct DeviceSpec {
  let simulatorName: String
  let folderName: String
  let size: CGSize
  /// Fraction of the canvas height reserved for the marketing copy above the device shot.
  let headerHeightRatio: CGFloat
}

struct Caption {
  let captureName: String
  let eyebrow: String
  let headline: String
}

let deviceSpecs = [
  // `simulatorName` must match the devices in fastlane/Snapfile — that is where the captures come
  // from. Both capture natively at an accepted size, so nothing is ever rescaled.
  DeviceSpec(
    simulatorName: "iPhone 17 Pro Max",
    folderName: "iPhone-6.9",
    size: CGSize(width: 1320.0, height: 2868.0),
    headerHeightRatio: 0.26
  ),
  DeviceSpec(
    simulatorName: "iPad Pro 13-inch (M5)",
    folderName: "iPad-13",
    size: CGSize(width: 2064.0, height: 2752.0),
    headerHeightRatio: 0.22
  )
]

let captions = [
  Caption(
    captureName: "01Readout",
    eyebrow: "01 · READOUT",
    headline: "The number is a readout, not a text field."
  ),
  Caption(
    captureName: "02Entry",
    eyebrow: "02 · ENTRY",
    headline: "Digits illegal in the current base are dimmed and dead — not hidden."
  ),
  Caption(
    captureName: "03History",
    eyebrow: "03 · HISTORY",
    headline: "Every value you commit stays, in the base you typed it."
  ),
  Caption(
    captureName: "04Settings",
    eyebrow: "04 · SETTINGS",
    headline: "Show only the bases you use. Thirty-six are one switch away."
  )
]

// MARK: Arguments

func argumentValue(_ flag: String, default defaultValue: String) -> String {
  let arguments = CommandLine.arguments
  guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
    return defaultValue
  }
  return arguments[index + 1]
}

let fileManager = FileManager.default
let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let inputDirectory = URL(
  fileURLWithPath: argumentValue("--input", default: "build/screenshots"),
  relativeTo: repositoryRoot
)
let outputDirectory = URL(
  fileURLWithPath: argumentValue("--output", default: "AppStoreAssets"),
  relativeTo: repositoryRoot
)

// MARK: Drawing

let locale = argumentValue("--locale", default: "en-US")

/// snapshot writes `<output>/<locale>/<Simulator Name>-<CaptureName>.png`.
func loadCapture(named name: String, for spec: DeviceSpec) -> NSBitmapImageRep? {
  let url = inputDirectory
    .appendingPathComponent(locale, isDirectory: true)
    .appendingPathComponent("\(spec.simulatorName)-\(name).png")
  guard let data = try? Data(contentsOf: url), let representation = NSBitmapImageRep(data: data) else {
    return nil
  }
  return representation
}

/// Shrinks `string` until it actually fits `rect`, and refuses to draw if it cannot.
///
/// Drawing at a fixed point size and hoping is how a headline ends up colliding with the device
/// shot below it — AppKit happily draws past the bottom of the rect it was given. Localised copy
/// makes this worse: German and French routinely run 30-40% longer than English.
func fittedFont(for string: String, startingAt maximumSize: CGFloat, in rect: NSRect, weight: NSFont.Weight) -> NSFont {
  let minimumSize = maximumSize * 0.6
  var size = maximumSize

  while size >= minimumSize {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.08

    let measured = NSAttributedString(string: string, attributes: [
      .font: font,
      .kern: -0.5,
      .paragraphStyle: paragraphStyle
    ]).boundingRect(
      with: NSSize(width: rect.width, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin]
    )

    if measured.height <= rect.height {
      return font
    }

    size -= maximumSize * 0.04
  }

  FileHandle.standardError.write(Data("""
  error: headline does not fit even at \(Int(minimumSize))pt:
    "\(string)"
  Shorten the copy, or raise headerHeightRatio for this device.

  """.utf8))
  exit(1)
}

func drawText(
  _ string: String,
  font: NSFont,
  color: NSColor,
  tracking: CGFloat,
  in rect: NSRect,
  alignment: NSTextAlignment = .left
) {
  let paragraphStyle = NSMutableParagraphStyle()
  paragraphStyle.alignment = alignment
  paragraphStyle.lineHeightMultiple = 1.08

  let attributed = NSAttributedString(string: string, attributes: [
    .font: font,
    .foregroundColor: color,
    .kern: tracking,
    .paragraphStyle: paragraphStyle
  ])

  attributed.draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
}

func compose(caption: Caption, capture: NSBitmapImageRep, spec: DeviceSpec) -> Data? {
  let width = Int(spec.size.width)
  let height = Int(spec.size.height)

  guard let canvas = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ) else {
    return nil
  }

  NSGraphicsContext.saveGraphicsState()
  defer { NSGraphicsContext.restoreGraphicsState() }
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)

  let canvasRect = NSRect(x: 0.0, y: 0.0, width: spec.size.width, height: spec.size.height)
  Palette.background.setFill()
  canvasRect.fill()

  let margin = spec.size.width * 0.08
  let headerHeight = spec.size.height * spec.headerHeightRatio

  // Eyebrow + headline sit in the top band; AppKit's origin is bottom-left.
  let eyebrowFont = NSFont.monospacedSystemFont(ofSize: spec.size.width * 0.018, weight: .medium)
  let headlineFont = NSFont.systemFont(ofSize: spec.size.width * 0.052, weight: .bold)

  let eyebrowRect = NSRect(
    x: margin,
    y: spec.size.height - margin - eyebrowFont.pointSize * 1.6,
    width: spec.size.width - margin * 2.0,
    height: eyebrowFont.pointSize * 1.6
  )
  drawText(caption.eyebrow, font: eyebrowFont, color: Palette.accent, tracking: 2.0, in: eyebrowRect)

  let headlineRect = NSRect(
    x: margin,
    y: spec.size.height - headerHeight,
    width: spec.size.width - margin * 2.0,
    height: headerHeight - margin - eyebrowFont.pointSize * 2.4
  )
  let fittedHeadline = fittedFont(
    for: caption.headline,
    startingAt: headlineFont.pointSize,
    in: headlineRect,
    weight: .bold
  )
  drawText(caption.headline, font: fittedHeadline, color: Palette.text, tracking: -0.5, in: headlineRect)

  // Device shot: fit inside the remaining area, preserving aspect ratio.
  let stageRect = NSRect(
    x: margin,
    y: margin,
    width: spec.size.width - margin * 2.0,
    height: spec.size.height - headerHeight - margin
  )
  let captureSize = CGSize(width: CGFloat(capture.pixelsWide), height: CGFloat(capture.pixelsHigh))
  let scale = min(stageRect.width / captureSize.width, stageRect.height / captureSize.height)
  let shotSize = CGSize(width: captureSize.width * scale, height: captureSize.height * scale)
  let shotRect = NSRect(
    x: stageRect.midX - shotSize.width / 2.0,
    y: stageRect.midY - shotSize.height / 2.0,
    width: shotSize.width,
    height: shotSize.height
  )

  let cornerRadius = shotSize.width * 0.055
  let shotPath = NSBezierPath(roundedRect: shotRect, xRadius: cornerRadius, yRadius: cornerRadius)

  Palette.panel.setFill()
  shotPath.fill()

  NSGraphicsContext.saveGraphicsState()
  shotPath.addClip()
  capture.draw(in: shotRect)
  NSGraphicsContext.restoreGraphicsState()

  // Hairline stroke — the instrument aesthetic is shadowless (docs/06).
  Palette.text.withAlphaComponent(0.14).setStroke()
  shotPath.lineWidth = max(1.0, spec.size.width * 0.0015)
  shotPath.stroke()

  return canvas.representation(using: .png, properties: [:])
}

// MARK: Run

guard fileManager.fileExists(atPath: inputDirectory.path) else {
  FileHandle.standardError.write(Data("""
  error: no captures at \(inputDirectory.path)

  Capture first:
    bundle exec fastlane ios screenshots

  """.utf8))
  exit(1)
}

var writtenCount = 0

for spec in deviceSpecs {
  let deviceDirectory = outputDirectory.appendingPathComponent(spec.folderName)
  try? fileManager.createDirectory(at: deviceDirectory, withIntermediateDirectories: true)

  for caption in captions {
    guard let capture = loadCapture(named: caption.captureName, for: spec) else {
      print("skip  \(spec.folderName)/\(caption.captureName) — capture missing")
      continue
    }

    guard let data = compose(caption: caption, capture: capture, spec: spec) else {
      print("skip  \(spec.folderName)/\(caption.captureName) — could not compose")
      continue
    }

    let outputURL = deviceDirectory.appendingPathComponent("\(caption.captureName).png")
    do {
      try data.write(to: outputURL, options: .atomic)
      writtenCount += 1
      print("write \(spec.folderName)/\(caption.captureName).png  \(Int(spec.size.width))×\(Int(spec.size.height))")
    } catch {
      print("skip  \(spec.folderName)/\(caption.captureName) — \(error.localizedDescription)")
    }
  }
}

print("\n\(writtenCount) asset(s) written to \(outputDirectory.path)")
