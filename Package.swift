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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.12/YEOFR.xcframework.zip",
      checksum: "6c92cc4f7dc15a474fac4e5c697861d5fd74b81f5b2d88db373579254cd599e2"
    )
  ]
)
