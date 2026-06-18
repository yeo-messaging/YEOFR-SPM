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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.7/YEOFR.xcframework.zip",
      checksum: "ab70969332f05d958f1507da50360cdf939e196dd44738aec3084e10d3eb9b79"
    )
  ]
)
