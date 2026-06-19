//
//  ChaChaPolyCryptor.swift
//  FRPilot
//
//  A custom `Cryptor` for the YEOFR SDK's `.custom(...)` encryption mode.
//  The SDK ships only `.plaintext` built-in, so authenticated encryption is
//  the consumer's responsibility via `.custom` — here, ChaChaPoly (an AEAD
//  from CryptoKit) keyed from a Keychain-resident 256-bit key.
//
//  Payload layout inside `EncryptedBlob`: `nonce(12) || ciphertext || tag(16)`
//  — `ChaChaPoly.SealedBox.combined`. The SDK owns the 2-byte
//  `[version][algorithmID]` framing around this (see `EncryptedBlob.serialized()`).
//

import CryptoKit
import Foundation
import YEOFR

struct ChaChaPolyCryptor: Cryptor {

    /// Custom algorithm IDs must be >= `customRangeStart` (0x80) so they never
    /// collide with the SDK's built-in cryptor IDs (0x00/0x01/0x02).
    let algorithmID: UInt8 = EncryptedBlob.AlgorithmID.customRangeStart

    private let key: SymmetricKey

    init(key: SymmetricKey) {
        self.key = key
    }

    /// Load-or-generate a 256-bit key from the iOS Keychain, reusing the SDK's
    /// public `KeychainKeyStore` (after-first-unlock, this-device-only) rather
    /// than hand-rolling key storage.
    static func makeWithKeychainKey(
        tag: String = "com.yeo.frpilot.tracker-key"
    ) throws -> ChaChaPolyCryptor {
        let raw = try KeychainKeyStore().loadOrGenerate(tag: tag, sizeBytes: 32)
        return ChaChaPolyCryptor(key: SymmetricKey(data: raw))
    }

    func encrypt(_ plaintext: Data) throws -> EncryptedBlob {
        do {
            // ChaChaPoly generates a fresh random nonce per seal — never reused.
            let sealed = try ChaChaPoly.seal(plaintext, using: key)
            return EncryptedBlob(algorithmID: algorithmID, payload: sealed.combined)
        } catch {
            throw CryptorError.underlying(message: "\(error)", osStatus: nil)
        }
    }

    func decrypt(_ blob: EncryptedBlob) throws -> Data {
        // Defend against a foreign blob fed to the wrong cryptor: the SDK keeps
        // a single configured cryptor and does not dispatch by algorithm ID, so
        // this check is our only guard.
        guard blob.algorithmID == algorithmID else {
            throw CryptorError.algorithmMismatch(expected: algorithmID, found: blob.algorithmID)
        }
        do {
            let box = try ChaChaPoly.SealedBox(combined: blob.payload)
            return try ChaChaPoly.open(box, using: key)
        } catch CryptoKitError.authenticationFailure {
            throw CryptorError.authenticationFailed
        } catch let error as CryptorError {
            throw error
        } catch {
            throw CryptorError.underlying(message: "\(error)", osStatus: nil)
        }
    }
}
