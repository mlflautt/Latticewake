import Foundation

enum DemoScene {
  static let canonicalJSON = """
  {"schemaVersion":"latticewake-scene-v0","sceneID":"standalone-demo","seed":"1","title":"Standalone Demo","createdFrom":null,"harmonicContext":{"tonic":"c","mode":"dorian","scaleDegrees":[0,2,3,5,7,9,10],"chordDegree":0,"chordQuality":"minor","inversion":0,"octaveReference":4,"tempoBPM":120,"tuningID":null},"terrain":{"kind":"mandelbrot","detail":0.5,"zoom":0.5,"offsetX":0.5,"offsetY":0.5,"rotation":0,"motion":0,"maxIterations":128,"normalization":1},"path":{"kind":"ellipse","rateRatio":0.5,"radiusX":0.5,"radiusY":0.5,"angle":0,"translationX":0.5,"translationY":0.5,"meander":0,"feedback":0,"spatialLimit":1},"roles":[{"id":"drone","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"0","voiceRoute":"internal","midiRoute":""},{"id":"pad","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"1","voiceRoute":"internal","midiRoute":""},{"id":"motifA","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"2","voiceRoute":"internal","midiRoute":""},{"id":"motifB","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"3","voiceRoute":"internal","midiRoute":""}]}
  """
}
