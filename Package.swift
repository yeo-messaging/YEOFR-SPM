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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.5/YEOFR.xcframework.zip",
      checksum: "0329374104d484e693c676e85ffba861c5403f6791975c5ebae13919e20f44c6"
    )
  ]
)
