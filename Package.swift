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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.3/YEOFR.xcframework.zip",
      checksum: "d889d87f7728a3fd451ead7a1f67bb3c3bb8016814ed7b5fea0b9872f1e0b0ac"
    )
  ]
)
