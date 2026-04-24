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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.13/YEOFR.xcframework.zip",
      checksum: "ac2e4955673c2c17e5263bccd54599603bf2d62715eba9d2ab0587d46f601878"
    )
  ]
)
