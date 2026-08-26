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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.10/YEOFR.xcframework.zip",
      checksum: "986ce01512dff26049c27a1d6a8b75804ffae72db2e89a0f21c788d50d73508d"
    )
  ]
)
