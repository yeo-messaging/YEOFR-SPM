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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.11.0/YEOFR.xcframework.zip",
      checksum: "94030053a21a3d21ac8ead72404ba4882aa60a897f6bca0de9b0fc5c3f2b5586"
    )
  ]
)
