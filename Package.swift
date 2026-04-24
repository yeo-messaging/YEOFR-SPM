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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.15/YEOFR.xcframework.zip",
      checksum: "e4f7747bd6053f0409a093ced336dc89d7330bb4e4d1f0f11ea1e7a19113bf46"
    )
  ]
)
