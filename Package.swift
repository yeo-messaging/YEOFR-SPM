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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.7.1/YEOFR.xcframework.zip",
      checksum: "bf868a24d31d2d69841a3547aa1cf04fe7c02f1de9d7af854ad41a2e50f18b0c"
    )
  ]
)
