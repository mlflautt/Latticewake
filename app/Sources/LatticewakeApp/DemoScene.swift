import Foundation

enum DemoScene {
  struct SignatureStarter: Identifiable {
    let id: Int
    let name: String
    let controls: SceneEditorControls
    let rolesEnabled: Bool

    func sceneBytes() throws -> Data {
      let source = rolesEnabled ? DemoScene.fourRoleJSON : DemoScene.gestureJSON
      let oldID = rolesEnabled ? "four-role-loop" : "gesture-terrain"
      let oldName = rolesEnabled ? "Four Role Loop" : "Gesture Terrain"
      let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
      let identified = source.replacingOccurrences(of: oldID, with: "signature-\(slug)")
        .replacingOccurrences(of: oldName, with: name)
      return try SceneEditorBridge.apply(controls, to: Data(identified.utf8))
    }
  }

  static let signatureStarters: [SignatureStarter] = {
    func controls(_ morph: Double, _ detail: Double, _ zoom: Double, _ bDetail: Double,
                  _ bZoom: Double, _ tone: Double, _ drive: Double, _ space: Double,
                  _ width: Double, _ attack: Double, _ release: Double,
                  _ rate: Double) -> SceneEditorControls {
      var value = SceneEditorControls()
      value.surfaceMorph = morph; value.terrainDetail = detail; value.terrainZoom = zoom
      value.layerBDetail = bDetail; value.layerBZoom = bZoom
      value.layerBOffsetX = 0.21 + morph * 0.37; value.layerBOffsetY = 0.74 - morph * 0.29
      value.tone = tone; value.drive = drive; value.space = space; value.stereoMotion = width
      value.attackSeconds = attack; value.releaseSeconds = release; value.traversalRateRatio = rate
      value.gain = 0.72
      return value
    }
    return [
      .init(id: 0, name: "Sustained Basin", controls: controls(0.18, 0.62, 0.08, 0.28, 0.42, 0.68, 0.08, 0.18, 0.20, 0.12, 0.82, 0.46), rolesEnabled: false),
      .init(id: 1, name: "Glass Thread", controls: controls(0.76, 0.84, 0.02, 0.91, 0.18, 0.92, 0.12, 0.31, 0.34, 0.008, 0.46, 0.88), rolesEnabled: false),
      .init(id: 2, name: "Warm Drift", controls: controls(0.42, 0.44, 0.17, 0.19, 0.61, 0.46, 0.33, 0.24, 0.26, 0.07, 0.68, 0.34), rolesEnabled: false),
      .init(id: 3, name: "Rough Orbit", controls: controls(0.61, 0.93, 0.27, 0.73, 0.04, 0.57, 0.74, 0.08, 0.44, 0.012, 0.24, 0.91), rolesEnabled: false),
      .init(id: 4, name: "Wide Bloom", controls: controls(0.53, 0.57, 0.11, 0.38, 0.73, 0.73, 0.17, 0.78, 0.86, 0.19, 1.24, 0.29), rolesEnabled: false),
      .init(id: 5, name: "Short Sparks", controls: controls(0.87, 0.96, 0.01, 0.66, 0.25, 0.88, 0.48, 0.13, 0.61, 0.002, 0.095, 0.95), rolesEnabled: false),
      .init(id: 6, name: "Deep Drone", controls: controls(0.29, 0.39, 0.32, 0.12, 0.82, 0.34, 0.41, 0.62, 0.72, 0.31, 1.62, 0.18), rolesEnabled: true),
      .init(id: 7, name: "Motif Current", controls: controls(0.67, 0.71, 0.06, 0.49, 0.48, 0.79, 0.29, 0.37, 0.57, 0.014, 0.33, 0.72), rolesEnabled: true)
    ]
  }()
  static var sustainedJSON: String {
    playableJSON.replacingOccurrences(of: "playable-starter", with: "sustained-terrain")
      .replacingOccurrences(of: "Playable Terrain", with: "Sustained Terrain")
      .replacingOccurrences(of: "\"enabled\":true", with: "\"enabled\":false")
  }
  static var gestureJSON: String {
    sustainedJSON.replacingOccurrences(of: "sustained-terrain", with: "gesture-terrain")
      .replacingOccurrences(of: "Sustained Terrain", with: "Gesture Terrain")
  }
  static var fourRoleJSON: String {
    playableJSON.replacingOccurrences(of: "playable-starter", with: "four-role-loop")
      .replacingOccurrences(of: "Playable Terrain", with: "Four Role Loop")
  }
  // An explicit alternative: never rewrite an existing user's saved scene.
  static var playableJSON: String {
    canonicalJSON.replacingOccurrences(of: "\"zoom\":0.5", with: "\"zoom\":0")
      .replacingOccurrences(of: "\"rateRatio\":0.5", with: "\"rateRatio\":1")
      .replacingOccurrences(of: "\"radiusY\":0.5", with: "\"radiusY\":0.3")
      .replacingOccurrences(of: "\"translationX\":0.5", with: "\"translationX\":0.6")
      .replacingOccurrences(of: "standalone-demo", with: "playable-starter")
      .replacingOccurrences(of: "Standalone Demo", with: "Playable Terrain")
  }
  static let canonicalJSON = """
  {"schemaVersion":"latticewake-scene-v0","sceneID":"standalone-demo","seed":"1","title":"Standalone Demo","createdFrom":null,"harmonicContext":{"tonic":"c","mode":"dorian","scaleDegrees":[0,2,3,5,7,9,10],"chordDegree":0,"chordQuality":"minor","inversion":0,"octaveReference":4,"tempoBPM":120,"tuningID":null},"terrain":{"kind":"mandelbrot","detail":0.5,"zoom":0.5,"offsetX":0.5,"offsetY":0.5,"rotation":0,"motion":0,"maxIterations":128,"normalization":1},"path":{"kind":"ellipse","rateRatio":0.5,"radiusX":0.5,"radiusY":0.5,"angle":0,"translationX":0.5,"translationY":0.5,"meander":0,"feedback":0,"spatialLimit":1},"roles":[{"id":"drone","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"0","voiceRoute":"internal","midiRoute":""},{"id":"pad","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"1","voiceRoute":"internal","midiRoute":""},{"id":"motifA","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"2","voiceRoute":"internal","midiRoute":""},{"id":"motifB","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"3","voiceRoute":"internal","midiRoute":""}]}
  """
}
