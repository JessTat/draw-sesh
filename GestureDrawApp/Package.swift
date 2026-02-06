// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "GestureDrawApp",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "GestureDrawApp", targets: ["GestureDrawApp"])
  ],
  targets: [
    .executableTarget(
      name: "GestureDrawApp",
      path: "Sources/GestureDrawApp"
    )
  ]
)
