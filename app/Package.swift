// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "Latticewake",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "LatticewakeApp", targets: ["LatticewakeApp"])],
  targets: [
    .target(name: "LatticewakeBridge", path: "Bridge", publicHeadersPath: "include", cxxSettings: [.unsafeFlags(["-std=c++20"])]),
    .executableTarget(name: "LatticewakeApp", dependencies: ["LatticewakeBridge"], path: "Sources/LatticewakeApp"),
    .testTarget(name: "LatticewakeAppTests", dependencies: ["LatticewakeApp"], path: "Tests/LatticewakeAppTests")
  ])
