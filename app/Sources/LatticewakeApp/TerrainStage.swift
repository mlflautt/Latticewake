import SwiftUI

private struct BridgeTerrainFramePoint {
  var value: Float = 0
  var pathX: Float = 0
  var pathY: Float = 0
  var iterations: UInt32 = 0
  var escaped: UInt32 = 0
}

@_silgen_name("lw_terrain_frame_scene_json") private func lw_terrain_frame_scene_json(
  _ json: UnsafePointer<CChar>, _ sampleOffset: UInt64, _ startPhase: Double, _ phaseStep: Double,
  _ points: UnsafeMutablePointer<BridgeTerrainFramePoint>, _ capacity: UInt32,
  _ pointCount: UnsafeMutablePointer<UInt32>
) -> Int32

struct TerrainStagePoint: Equatable {
  let value: Double
  let x: Double
  let y: Double
  let escaped: Bool
}

struct TerrainStageSnapshot: Equatable {
  let sampleOffset: UInt64
  let points: [TerrainStagePoint]
  static let empty = TerrainStageSnapshot(sampleOffset: 0, points: [])
}

@MainActor final class TerrainStageModel: ObservableObject {
  @Published private(set) var snapshot = TerrainStageSnapshot.empty

  func prepare(sceneBytes: Data, sampleOffset: UInt64 = 0) throws {
    guard let json = String(data: sceneBytes, encoding: .utf8) else {
      throw NSError(domain: "Latticewake", code: 10,
                    userInfo: [NSLocalizedDescriptionKey: "Terrain frame requires UTF-8 Scene bytes"])
    }
    var bridgePoints = Array(repeating: BridgeTerrainFramePoint(), count: 256)
    var pointCount: UInt32 = 0
    let result = json.withCString { source in
      bridgePoints.withUnsafeMutableBufferPointer { points in
        withUnsafeMutablePointer(to: &pointCount) { count in
          lw_terrain_frame_scene_json(source, sampleOffset, 0, 1.0 / 255.0,
                                      points.baseAddress!, UInt32(points.count), count)
        }
      }
    }
    guard result != 0, pointCount > 1, pointCount <= bridgePoints.count else {
      throw NSError(domain: "Latticewake", code: 11,
                    userInfo: [NSLocalizedDescriptionKey: "Could not prepare terrain frame"])
    }
    snapshot = TerrainStageSnapshot(
      sampleOffset: sampleOffset,
      points: bridgePoints.prefix(Int(pointCount)).map {
        TerrainStagePoint(value: Double($0.value), x: Double($0.pathX), y: Double($0.pathY),
                          escaped: $0.escaped != 0)
      })
  }
}

struct TerrainStageView: View {
  let snapshot: TerrainStageSnapshot

  var body: some View {
    Canvas { context, size in
      drawGrid(context: context, size: size)
      guard snapshot.points.count > 1 else { return }

      var trace = Path()
      for (index, point) in snapshot.points.enumerated() {
        let position = project(point, in: size)
        if index == 0 { trace.move(to: position) } else { trace.addLine(to: position) }
      }
      context.stroke(trace, with: .linearGradient(
        Gradient(colors: [.cyan.opacity(0.25), .mint.opacity(0.9), .pink.opacity(0.75)]),
        startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 1.5)

      for point in snapshot.points {
        let position = project(point, in: size)
        let intensity = max(0.15, min(1, point.value))
        let color: Color = point.escaped ? .pink : .cyan
        context.fill(Path(ellipseIn: CGRect(x: position.x - 2.5, y: position.y - 2.5,
                                            width: 5, height: 5)),
                     with: .color(color.opacity(intensity)))
      }

      if let current = snapshot.points.last {
        let position = project(current, in: size)
        context.stroke(Path(ellipseIn: CGRect(x: position.x - 7, y: position.y - 7,
                                              width: 14, height: 14)),
                       with: .color(.white), lineWidth: 1)
      }
    }
    .accessibilityLabel("Terrain Stage trace with \(snapshot.points.count) terrain samples")
  }

  private func project(_ point: TerrainStagePoint, in size: CGSize) -> CGPoint {
    CGPoint(x: (point.x + 1) * 0.5 * size.width,
            y: (1 - (point.y + 1) * 0.5) * size.height)
  }

  private func drawGrid(context: GraphicsContext, size: CGSize) {
    var grid = Path()
    for fraction in [0.25, 0.5, 0.75] {
      grid.move(to: CGPoint(x: size.width * fraction, y: 0))
      grid.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
      grid.move(to: CGPoint(x: 0, y: size.height * fraction))
      grid.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
    }
    context.stroke(grid, with: .color(.white.opacity(0.08)), lineWidth: 1)
  }
}
