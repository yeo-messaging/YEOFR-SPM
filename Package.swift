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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.11/YEOFR.xcframework.zip",
      checksum: "f52968bd4131a5e629ef9496bea607ab3f0c202c4b619bb871e5fad7e5a654fc"
    )
  ]
)
