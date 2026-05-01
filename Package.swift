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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.5.0/YEOFR.xcframework.zip",
      checksum: "f2f0440b58897ccaf1c21ff741e62ea6a6ec0e3f99e932c87cad0cbd55603312"
    )
  ]
)
