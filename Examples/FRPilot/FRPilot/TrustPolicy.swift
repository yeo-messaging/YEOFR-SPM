//
//  TrustPolicy.swift
//  FRPilot
//

import Foundation

/// The view-facing verdict, mapped from the SDK's `FaceTrustUpdate`. A plain
/// enum with no `import YEOFR`, so the views preview on the simulator.
enum TrustVerdict: Equatable {
    case noFace
    case badFraming
    case notTrusted(similarity: Float?)
    case trusted(name: String?, similarity: Float?)
}
