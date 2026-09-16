import MetalKit
import SwiftUI

private struct TerrainVertex {
  var position: SIMD2<Float>
  var color: SIMD4<Float>
}

private final class TerrainMetalRenderer: NSObject, MTKViewDelegate {
  private let device: MTLDevice
  private let queue: MTLCommandQueue
  private let pipeline: MTLRenderPipelineState
  private var vertices: [TerrainVertex] = []
  private var vertexBuffer: MTLBuffer?

  @MainActor init?(view: MTKView) {
    guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
          let queue = device.makeCommandQueue() else { return nil }
    self.device = device
    self.queue = queue
    view.device = device
    view.colorPixelFormat = .bgra8Unorm
    view.clearColor = MTLClearColor(red: 0.015, green: 0.027, blue: 0.060, alpha: 1)
    view.isPaused = true
    view.enableSetNeedsDisplay = true
    let source = """
    #include <metal_stdlib>
    using namespace metal;
    struct Vertex { float2 position; float4 color; };
    struct Output { float4 position [[position]]; float4 color; };
    vertex Output terrain_vertex(const device Vertex* vertices [[buffer(0)]], uint id [[vertex_id]]) {
      Output output; output.position = float4(vertices[id].position, 0.0, 1.0); output.color = vertices[id].color; return output;
    }
    fragment float4 terrain_fragment(Output input [[stage_in]]) { return input.color; }
    """
    do {
      let library = try device.makeLibrary(source: source, options: nil)
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.vertexFunction = library.makeFunction(name: "terrain_vertex")
      descriptor.fragmentFunction = library.makeFunction(name: "terrain_fragment")
      descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
      pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    } catch { return nil }
    super.init()
    view.delegate = self
  }

  func update(snapshot: TerrainStageSnapshot) {
    vertices = snapshot.points.map { point in
      let intensity = Float(max(0.28, min(1.0, point.value)))
      let color: SIMD4<Float> = point.escaped
        ? SIMD4(1.0, 0.34, 0.46, intensity)
        : SIMD4(0.08, 0.88, 0.94, intensity)
      return TerrainVertex(position: SIMD2(Float(point.x), Float(point.y)), color: color)
    }
    if vertices.isEmpty { vertexBuffer = nil }
    else {
      vertexBuffer = vertices.withUnsafeBytes { bytes in
        device.makeBuffer(bytes: bytes.baseAddress!, length: bytes.count, options: .storageModeShared)
      }
    }
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

  func draw(in view: MTKView) {
    guard let descriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable,
          let command = queue.makeCommandBuffer(),
          let encoder = command.makeRenderCommandEncoder(descriptor: descriptor) else { return }
    if let vertexBuffer, !vertices.isEmpty {
      encoder.setRenderPipelineState(pipeline)
      encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertices.count)
    }
    encoder.endEncoding()
    command.present(drawable)
    command.commit()
  }
}

private struct TerrainMetalRepresentable: NSViewRepresentable {
  let snapshot: TerrainStageSnapshot

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeNSView(context: Context) -> MTKView {
    let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    view.wantsLayer = true
    context.coordinator.renderer = TerrainMetalRenderer(view: view)
    context.coordinator.renderer?.update(snapshot: snapshot)
    view.setNeedsDisplay(view.bounds)
    return view
  }

  func updateNSView(_ view: MTKView, context: Context) {
    context.coordinator.renderer?.update(snapshot: snapshot)
    view.setNeedsDisplay(view.bounds)
  }

  final class Coordinator { var renderer: TerrainMetalRenderer? }
}

struct TerrainContourSurface: View {
  let snapshot: TerrainStageSnapshot
  let pointer: CGPoint?
  let heldNotes: [Int]
  let activeLanes: Int

  var body: some View {
    ZStack {
      // Canvas is the stable baseline while the MTKView path is re-admitted for
      // idle cost on the target OS. It consumes the same immutable snapshot.
      TerrainStageView(snapshot: snapshot)
      Canvas { context, size in
        drawContours(context: context, size: size)
        if let pointer {
          context.stroke(Path(ellipseIn: CGRect(x: pointer.x - 8, y: pointer.y - 8, width: 16, height: 16)),
                         with: .color(.cyan), lineWidth: 2)
        }
      }
      .allowsHitTesting(false)
      VStack {
        HStack {
          StageBadge(label: "DIRECT", value: heldNotes.isEmpty ? "idle" : "\(heldNotes.count) voice", color: .cyan)
          Spacer()
          StageBadge(label: "LANES", value: "\(activeLanes) active", color: .mint)
        }
        Spacer()
        HStack {
          Text("SAMPLING PATH").font(.caption2.monospaced()).foregroundStyle(.secondary)
          Spacer()
          Text("\(snapshot.points.count) points").font(.caption2.monospaced()).foregroundStyle(.secondary)
        }
      }
      .padding(12)
      .allowsHitTesting(false)
    }
    .background(Color(red: 0.015, green: 0.027, blue: 0.060))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.cyan.opacity(0.22), lineWidth: 1))
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Authoritative terrain surface with \(snapshot.points.count) immutable terrain samples, \(heldNotes.count) direct voices, and \(activeLanes) active lanes")
  }

  private func drawContours(context: GraphicsContext, size: CGSize) {
    var grid = Path()
    for fraction in [0.2, 0.4, 0.6, 0.8] {
      grid.move(to: CGPoint(x: size.width * fraction, y: 0)); grid.addLine(to: CGPoint(x: size.width * fraction, y: size.height))
      grid.move(to: CGPoint(x: 0, y: size.height * fraction)); grid.addLine(to: CGPoint(x: size.width, y: size.height * fraction))
    }
    context.stroke(grid, with: .color(.white.opacity(0.07)), lineWidth: 1)
    guard snapshot.points.count > 2 else { return }
    for level in stride(from: 0.2, through: 0.8, by: 0.2) {
      var contour = Path()
      var drawing = false
      for point in snapshot.points where abs(point.value - level) < 0.035 {
        let position = CGPoint(x: (point.x + 1) * 0.5 * size.width, y: (1 - (point.y + 1) * 0.5) * size.height)
        if drawing { contour.addLine(to: position) } else { contour.move(to: position); drawing = true }
      }
      context.stroke(contour, with: .color(.cyan.opacity(0.10)), lineWidth: 0.7)
    }
  }
}

private struct StageBadge: View {
  let label: String
  let value: String
  let color: Color
  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(label).font(.caption2.monospaced()).foregroundStyle(color)
      Text(value).font(.caption2).foregroundStyle(.white.opacity(0.8))
    }
    .padding(.horizontal, 8).padding(.vertical, 5)
    .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 7))
  }
}

struct StageRoleDeck: View {
  let roles: [RoleControl]
  let activeLanes: Int
  let running: Bool
  private let colors: [Color] = [.orange, .purple, .mint, .pink]

  var body: some View {
    HStack(spacing: 8) {
      ForEach(roles) { role in
        let active = running && role.enabled && role.id < activeLanes
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 5) {
            Circle().fill(active ? colors[role.id] : .secondary.opacity(0.45)).frame(width: 7, height: 7)
            Text(RoleControl.names[role.id]).font(.caption.weight(.semibold))
          }
          Text(role.enabled ? (active ? "sounding" : "armed") : "muted")
            .font(.caption2.monospaced()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(colors[role.id].opacity(active ? 0.18 : 0.06), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(colors[role.id].opacity(role.enabled ? 0.45 : 0.15), lineWidth: 1))
        .accessibilityLabel("\(RoleControl.names[role.id]), \(role.enabled ? (active ? "sounding" : "armed") : "muted")")
      }
    }
    .accessibilityLabel("Four role performance strip")
  }
}

struct StageDrawer<Content: View>: View {
  let title: String
  let color: Color
  @ViewBuilder let content: Content
  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title.uppercased()).font(.caption.monospaced()).foregroundStyle(color)
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.18), lineWidth: 1))
  }
}
