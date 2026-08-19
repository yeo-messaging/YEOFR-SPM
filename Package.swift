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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.9.0/YEOFR.xcframework.zip",
      checksum: "2ad329c0498923fc8c4bb5d9a5c68bd1df572a1548a111d3674cd20bb89f9002"
    )
  ]
)
