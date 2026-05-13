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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.4/YEOFR.xcframework.zip",
      checksum: "7dccaa04ff54f33f89cb33b554c3dba88e8c883c40b018a6038c869e6fd9b159"
    )
  ]
)
