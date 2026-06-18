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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.8/YEOFR.xcframework.zip",
      checksum: "d501cb7fedbe60009a91998492d6041feef5cec49b94f5d1af8f5032630e4a4d"
    )
  ]
)
