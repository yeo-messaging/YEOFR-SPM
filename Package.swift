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
      checksum: "756187e98a012596d5024ac60bb41816784ba0f81aabb52581ce592782ae0202"
    )
  ]
)
