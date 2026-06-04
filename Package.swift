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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.4/YEOFR.xcframework.zip",
      checksum: "59b4076f4b4a06f6343bfe56fc4f962a2fc182522630c476cc3c11e498de9fef"
    )
  ]
)
