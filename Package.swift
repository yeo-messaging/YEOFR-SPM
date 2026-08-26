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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.9/YEOFR.xcframework.zip",
      checksum: "73df634dbc33b11bc8bb3b5d610f433b080281f4651246c324e8734c58e23c0c"
    )
  ]
)
