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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.1/YEOFR.xcframework.zip",
      checksum: "fe26dfec751f5187c26a60ddde640f50bb3ccb14d0961b088bcfdacc8d1f41d4"
    )
  ]
)
