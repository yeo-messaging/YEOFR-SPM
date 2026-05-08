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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.2/YEOFR.xcframework.zip",
      checksum: "8710e7fe6cec4c44cbf9a258fdd0eebb7c44d7ca3ed27f71e522a78c7d295bc8"
    )
  ]
)
