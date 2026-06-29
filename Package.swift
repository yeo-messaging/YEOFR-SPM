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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.7.2/YEOFR.xcframework.zip",
      checksum: "30f15fff381ca4689be3464de1f2e49b95b58cc3a20549bbc8d99ffabf576413"
    )
  ]
)
