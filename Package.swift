// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17), .macOS("26.0")],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.11.5/YEOFR.xcframework.zip",
      checksum: "44931fd6ef2099759f591e8511cb3c9ebf389c8952baf01a700e1696a2cce8e6"
    )
  ]
)
