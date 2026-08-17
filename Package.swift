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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.9.0-qa.3/YEOFR.xcframework.zip",
      checksum: "87a5bb78d3fc701fdac3a6affaeab557f0e20e5d450d2fac2163c101b657c357"
    )
  ]
)
