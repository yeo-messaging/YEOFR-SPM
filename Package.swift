// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v12)],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.3.102/YEOFR.xcframework.zip",
      checksum: "e14c9f1d1e82b4b35b1bcfef9cd4b14ef5f6d5eae05eb3804c7a3bdd1600c249"
    )
  ]
)
