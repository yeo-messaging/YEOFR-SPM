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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.7.0/YEOFR.xcframework.zip",
      checksum: "d6ab3f98e0f796f939c21b5bb554caed82d1127df12f39e95dc7dbe73d47a627"
    )
  ]
)
