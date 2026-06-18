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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.7/YEOFR.xcframework.zip",
      checksum: "1c695a143f6eed4df8d6a6520ac7d8b2326966ef41e75bcae6a022b4ea0979c9"
    )
  ]
)
