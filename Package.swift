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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.2/YEOFR.xcframework.zip",
      checksum: "666346376070a8422416aa2cc8a3a809443fec260abdb8ff977ddab65500ddbb"
    )
  ]
)
