//
// DeviceAuthority.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import Foundation
import Security

public struct DeviceAuthority {
    public let name: String
    public let bundle: Bundle

    public init(name: String, bundle: Bundle = .main) {
        self.name = name
        self.bundle = bundle
    }

    internal func determineAuthorisationStatus() throws -> Bool {
        guard let path = bundle.path(forResource: name, ofType: "cer") else {
            throw AuthorisationStatusError.missingCertificate
        }

        let data = try NSData(contentsOfFile: path) as CFData
        let certificate = SecCertificateCreateWithData(nil, data)
        let policy = SecPolicyCreateBasicX509()

        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)

        guard let unwrappedTrust = trust else {
            throw AuthorisationStatusError.missingTrust(status)
        }

        // TODO: investigate available async APIs and whether we can make this work with async/await
        // TODO: investigate MainActor and thread safety

        if #available(iOS 12.0, *) {
            var error: CFError?

            guard SecTrustEvaluateWithError(unwrappedTrust, &error) else {
                if let error {
                    throw AuthorisationStatusError.failedEvaluation(error)
                } else {
                    throw AuthorisationStatusError.missingError
                }
            }
        } else {
            // TODO: verify pre iOS 12 functionality

            var result: SecTrustResultType = .unspecified
            let status = SecTrustEvaluate(unwrappedTrust, &result)

            guard result == .proceed else {
                throw AuthorisationStatusError.failedEvaluation(result, status)
            }
        }

        // Passed evaluation
        return true
    }

    /// Determines the current device's authorisation status, defaulting to `false` in the case of any thrown failure.
    public var isAuthorised: Bool {
        (try? determineAuthorisationStatus()) ?? false
    }
}

public enum AuthorisationStatusError: Error {
    // TODO: improve error names/descriptions
    // TODO: convert to LocalizedError and provide helpful messages

    case missingCertificate
    case missingTrust(OSStatus)
    case failedEvaluation(CFError)
    case failedEvaluation(SecTrustResultType, OSStatus)
    case missingError
}
