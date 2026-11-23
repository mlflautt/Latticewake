import AppKit
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageTerrainAssetError: LocalizedError {
  case unreadableImage
  case tooLarge
  case invalidField

  var errorDescription: String? {
    switch self {
    case .unreadableImage: "The selected file could not be decoded as an image."
    case .tooLarge: "The image exceeds Latticewake's bounded import size."
    case .invalidField: "The image did not produce a valid terrain field."
    }
  }
}

/// Durable, bounded import result. `fieldBytes` is the canonical `LWSF` v1
/// grid; `sourcePreviewPNG` lets a saved scene retain its recognizable source
/// plane without depending on the original file path.
struct ImageTerrainAsset: Codable, Equatable, Identifiable, Sendable {
  static let schema = "latticewake-image-terrain-v1"
  static let provider = "luminance-srgb-center-crop-v1"
  static let edge = 256

  let schemaVersion: String
  let id: String
  let sourceName: String
  let sourceSHA256: String
  let providerVersion: String
  let width: Int
  let height: Int
  let fieldBytes: Data
  let sourcePreviewPNG: Data

  var contentHash: String { id }

  init(sourceSHA256: String, sourceName: String = "Imported image", fieldBytes: Data, sourcePreviewPNG: Data) throws {
    let decoded = try Self.decodeField(fieldBytes)
    schemaVersion = Self.schema
    id = Self.hash(fieldBytes)
    self.sourceName = sourceName
    self.sourceSHA256 = sourceSHA256
    providerVersion = Self.provider
    width = decoded.width
    height = decoded.height
    self.fieldBytes = fieldBytes
    self.sourcePreviewPNG = sourcePreviewPNG
  }

  func samples() throws -> [UInt16] {
    let decoded = try Self.decodeField(fieldBytes)
    guard decoded.width == width, decoded.height == height,
          Self.hash(fieldBytes) == id else { throw ImageTerrainAssetError.invalidField }
    return decoded.samples
  }

  var previewImage: NSImage? { NSImage(data: sourcePreviewPNG) }

  var interpretationImage: NSImage? {
    guard let decoded = try? Self.decodeField(fieldBytes) else { return nil }
    var gray = decoded.samples.map { UInt8($0 >> 8) }
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let cgImage = gray.withUnsafeMutableBytes { pixels -> CGImage? in
      guard let context = CGContext(data: pixels.baseAddress, width: decoded.width, height: decoded.height,
                                    bitsPerComponent: 8, bytesPerRow: decoded.width,
                                    space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
      return context.makeImage()
    }
    return cgImage.map { NSImage(cgImage: $0, size: NSSize(width: decoded.width, height: decoded.height)) }
  }

  func contourSegments(maximum: Int = 4096) -> [TerrainContourSegment] {
    guard let decoded = try? Self.decodeField(fieldBytes), maximum > 0 else { return [] }
    let levels: [UInt16] = [16_384, 32_768, 49_152]
    var result: [TerrainContourSegment] = []
    result.reserveCapacity(min(maximum, 2048))
    let w = decoded.width
    let h = decoded.height
    for level in levels {
      for y in 0..<(h - 1) {
        for x in 0..<(w - 1) where result.count < maximum {
          let values = [decoded.samples[y * w + x], decoded.samples[y * w + x + 1],
                        decoded.samples[(y + 1) * w + x + 1], decoded.samples[(y + 1) * w + x]]
          let corners = [CGPoint(x: Double(x), y: Double(y)), CGPoint(x: Double(x + 1), y: Double(y)),
                         CGPoint(x: Double(x + 1), y: Double(y + 1)), CGPoint(x: Double(x), y: Double(y + 1))]
          var hits: [CGPoint] = []
          for edge in 0..<4 {
            let next = (edge + 1) % 4
            let a = values[edge]
            let b = values[next]
            guard (a < level && b >= level) || (a >= level && b < level) else { continue }
            let fraction = Double(Int(level) - Int(a)) / Double(Int(b) - Int(a))
            let p = corners[edge]
            let q = corners[next]
            hits.append(CGPoint(x: (p.x + (q.x - p.x) * fraction) / Double(w - 1),
                                y: (p.y + (q.y - p.y) * fraction) / Double(h - 1)))
          }
          if hits.count >= 2 {
            result.append(TerrainContourSegment(start: hits[0], end: hits[1]))
            if hits.count == 4 && result.count < maximum {
              result.append(TerrainContourSegment(start: hits[2], end: hits[3]))
            }
          }
        }
        if result.count >= maximum { break }
      }
      if result.count >= maximum { break }
    }
    return result
  }

  func sampledPathVariation(_ path: [CGPoint]) -> Double {
    guard let decoded = try? Self.decodeField(fieldBytes), !path.isEmpty else { return 0 }
    let w = decoded.width
    let h = decoded.height
    var minimum = 1.0
    var maximum = 0.0
    for point in path {
      let px = min(1, max(0, (point.x + 1) * 0.5)) * Double(w - 1)
      let py = min(1, max(0, (1 - point.y) * 0.5)) * Double(h - 1)
      let x0 = Int(px); let y0 = Int(py)
      let x1 = min(x0 + 1, w - 1); let y1 = min(y0 + 1, h - 1)
      let tx = px - Double(x0); let ty = py - Double(y0)
      func height(_ x: Int, _ y: Int) -> Double {
        Double(decoded.samples[y * w + x]) / 65535
      }
      let top = height(x0, y0) + (height(x1, y0) - height(x0, y0)) * tx
      let bottom = height(x0, y1) + (height(x1, y1) - height(x0, y1)) * tx
      let value = top + (bottom - top) * ty
      minimum = min(minimum, value); maximum = max(maximum, value)
    }
    return maximum - minimum
  }

  static func importImage(at url: URL) throws -> ImageTerrainAsset {
    let sourceData = try Data(contentsOf: url, options: [.mappedIfSafe])
    let sourceHash = hash(sourceData)
    guard sourceData.count <= 64 * 1024 * 1024,
          let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let sourceWidth = properties[kCGImagePropertyPixelWidth] as? Int,
          let sourceHeight = properties[kCGImagePropertyPixelHeight] as? Int else {
      throw ImageTerrainAssetError.unreadableImage
    }
    guard sourceWidth > 1, sourceHeight > 1, sourceWidth <= 1_000_000, sourceHeight <= 1_000_000,
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048,
            kCGImageSourceShouldCacheImmediately: true
          ] as CFDictionary) else { throw ImageTerrainAssetError.tooLarge }
    let width = edge
    let height = edge
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bytesPerPixel = 4
    var rgba = [UInt8](repeating: 127, count: width * height * bytesPerPixel)
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    var croppedPreview: CGImage?
    let rendered = rgba.withUnsafeMutableBytes { buffer -> Bool in
      guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                    bitsPerComponent: 8, bytesPerRow: width * bytesPerPixel,
                                    space: colorSpace, bitmapInfo: bitmapInfo) else { return false }
      context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      let scale = max(Double(width) / Double(image.width), Double(height) / Double(image.height))
      let drawWidth = Double(image.width) * scale
      let drawHeight = Double(image.height) * scale
      let drawRect = CGRect(x: (Double(width) - drawWidth) * 0.5,
                            y: (Double(height) - drawHeight) * 0.5,
                            width: drawWidth, height: drawHeight)
      context.interpolationQuality = .high
      context.draw(image, in: drawRect)
      croppedPreview = context.makeImage()
      return true
    }
    guard rendered, let croppedPreview else { throw ImageTerrainAssetError.unreadableImage }

    var field = Data([0x4c, 0x57, 0x53, 0x46, 0x00, 0x01]) // "LWSF", version 1
    field.appendBE(UInt16(width))
    field.appendBE(UInt16(height))
    for index in 0..<(width * height) {
      let offset = index * bytesPerPixel
      let red = Int(rgba[offset])
      let green = Int(rgba[offset + 1])
      let blue = Int(rgba[offset + 2])
      let alpha = Int(rgba[offset + 3])
      let r = (red * alpha + 127 * (255 - alpha) + 127) / 255
      let g = (green * alpha + 127 * (255 - alpha) + 127) / 255
      let b = (blue * alpha + 127 * (255 - alpha) + 127) / 255
      let luminance = UInt8((54 * r + 183 * g + 19 * b + 128) >> 8)
      field.appendBE(UInt16(luminance) * 257)
    }
    let preview = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(preview, UTType.png.identifier as CFString, 1, nil) else {
      throw ImageTerrainAssetError.unreadableImage
    }
    CGImageDestinationAddImage(destination, croppedPreview, nil)
    guard CGImageDestinationFinalize(destination) else { throw ImageTerrainAssetError.unreadableImage }
    return try ImageTerrainAsset(sourceSHA256: sourceHash, sourceName: url.lastPathComponent,
                                 fieldBytes: field, sourcePreviewPNG: preview as Data)
  }

  static func decodeField(_ data: Data) throws -> (width: Int, height: Int, samples: [UInt16]) {
    guard data.count >= 10, Array(data.prefix(6)) == [0x4c, 0x57, 0x53, 0x46, 0x00, 0x01] else {
      throw ImageTerrainAssetError.invalidField
    }
    let width = Int(data.readBE(at: 6))
    let height = Int(data.readBE(at: 8))
    guard width > 1, height > 1, width <= edge, height <= edge,
          data.count == 10 + width * height * 2 else { throw ImageTerrainAssetError.invalidField }
    var samples = [UInt16]()
    samples.reserveCapacity(width * height)
    for offset in stride(from: 10, to: data.count, by: 2) { samples.append(data.readBE(at: offset)) }
    return (width, height, samples)
  }

  static func hash(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

struct TerrainContourSegment: Equatable {
  let start: CGPoint
  let end: CGPoint
}

private extension Data {
  mutating func appendBE(_ value: UInt16) {
    append(UInt8((value >> 8) & 0xff)); append(UInt8(value & 0xff))
  }

  func readBE(at offset: Int) -> UInt16 {
    (UInt16(self[offset]) << 8) | UInt16(self[offset + 1])
  }
}
