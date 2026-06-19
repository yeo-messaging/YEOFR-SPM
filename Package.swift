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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.9/YEOFR.xcframework.zip",
      checksum: "1fc5ba6264eb7b34389b657c6db06cb77301243201f0d2bc71a62324a8615421"
    )
  ]
)
