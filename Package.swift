// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.6/YEOFR.xcframework.zip",
      checksum: "532cff9813d4f6ae777cd584a2eab55e65f5da0be6249a3d4908f4fc58efd90a"
    )
  ]
)
