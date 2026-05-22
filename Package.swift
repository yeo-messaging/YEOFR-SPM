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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.0/YEOFR.xcframework.zip",
      checksum: "4b2fec4f228e6c54300982e64209eba92ceae70a71be01b7597a89bf2195382e"
    )
  ]
)
