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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.3/YEOFR.xcframework.zip",
      checksum: "647449b3fa8c1180f3e011fb5013860fb16ec8105bd66a3fee7b878de90fa16a"
    )
  ]
)
