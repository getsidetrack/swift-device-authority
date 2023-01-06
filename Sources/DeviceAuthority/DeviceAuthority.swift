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
    
    // Async/Await (Swift Concurrency) was released in iOS 13
    @available(iOS 13.0.0, *)
    public func determineAuthorisationStatus() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let certificate = try loadCertificate() // provided by client
                let trust = try createTrust(from: certificate)
                
                let queue = DispatchQueue.global(qos: .userInteractive)
                queue.async {
                    // Queue completion is called on *must* be same as the queue the function itself is called on.
                    // Without this, it will crash.
                    SecTrustEvaluateAsyncWithError(trust, queue) { _, success, error in
                        if let error = createError(from: error) {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if success == false {
                            continuation.resume(throwing: AuthorisationStatusError.failedWithoutError)
                            return
                        }
                        
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Completion-style signature for compatibility purposes
    public func determineAuthorisationStatus(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let certificate = try loadCertificate() // provided by client
            let trust = try createTrust(from: certificate)
            
            SecTrustEvaluateAsync(trust, .global(qos: .userInteractive)) { trust, result in
                // Unfortunately, this API does not give us rich APIs out of the box.
                if let error = createError(from: result, trust: trust) {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Sync API
    public func determineAuthorisationStatusSync() throws {
        precondition(Thread.isMainThread == false, "This method should not be called on the main thread.")
        
        let certificate = try loadCertificate() // provided by client
        let trust = try createTrust(from: certificate)
        
        if #available(iOS 12.0, *) {
            var error: CFError?
            
            guard SecTrustEvaluateWithError(trust, &error) else {
                if let error = createError(from: error) {
                    throw error
                } else {
                    throw AuthorisationStatusError.failedWithoutError
                }
            }
        } else {
            var result: SecTrustResultType = .unspecified
            SecTrustEvaluate(trust, &result)
            
            if let error = createError(from: result, trust: trust) {
                throw error
            }
        }
    }
    
    // MARK: - Helpers
    
    internal func loadCertificate() throws -> SecCertificate {
        guard let path = bundle.path(forResource: name, ofType: "cer") else {
            throw AuthorisationStatusError.missingCertificate
        }

        guard let data = NSData(contentsOfFile: path), !data.isEmpty else {
            throw AuthorisationStatusError.missingCertificate
        }
        
        guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
            // Without this check, `SecTrustCreateWithCertificates` will throw a -50 error (errSecParam)
            throw AuthorisationStatusError.invalidCertificate
        }
        
        return certificate
    }
    
    internal func createTrust(from certificate: SecCertificate) throws -> SecTrust {
        let policy = SecPolicyCreateBasicX509()
        
        var trust: SecTrust?
        SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)
        
        guard let unwrappedTrust = trust else {
            // This will get triggered if your certificate is encoded using PEM.
            // `SecTrustCreateWithCertificates` expects certificates to use the DER encoding strategy.
            throw AuthorisationStatusError.invalidCertificate
        }
        
        return unwrappedTrust
    }
    
    // MARK: - Error Helpers
    
    internal func createError(from resultType: SecTrustResultType, trust: SecTrust) -> AuthorisationStatusError? {
        if resultType == .proceed {
            return nil
        }
        
        let trustResult = SecTrustCopyResult(trust) as? [String: Any]
        let trustResultDetails = trustResult?["TrustResultDetails"] as? [[String: Any]]
        
        if trustResultDetails?.first?.keys.contains("MissingIntermediate") == true {
            return AuthorisationStatusError.untrusted
        } else {
            return AuthorisationStatusError.failedWithResult(resultType)
        }
    }
    
    internal func createError(from error: CFError?) -> Error? {
        guard let error = error else {
            return nil
        }
        
        let domain = CFErrorGetDomain(error) as String
        let code = CFErrorGetCode(error)
        
        if domain == NSOSStatusErrorDomain, code == -25318 { // NSOSStatusErrorDomain: errSecCreateChainFailed
            // “<certificate name>” certificate is not trusted
            return AuthorisationStatusError.untrusted
        }
        
        return error
    }
}

public enum AuthorisationStatusError: LocalizedError {
    // A certificate could not be found with the provided name
    case missingCertificate
    
    // A certificate was found, but was in an invalid format
    case invalidCertificate
    
    // This device is not trusted.
    case untrusted
    
    // This device failed to evaluate, but we could identify why.
    case failedWithResult(SecTrustResultType)
    
    // This device failed to evaluate, but no error was thrown.
    case failedWithoutError
    
    public var errorDescription: String? {
        switch self {
        case .missingCertificate:
            return NSLocalizedString(
                "A certificate could not be found with the provided name",
                comment: "device-authority.missing-certificate"
            )
        case .invalidCertificate:
            return NSLocalizedString(
                "A certificate was found, but was in an invalid format",
                comment: "device-authority.invalid-certificate"
            )
        case .untrusted:
            return NSLocalizedString(
                "This device is not trusted.",
                comment: "device-authority.untrusted"
            )
        case .failedWithResult:
            return NSLocalizedString(
                "This device failed to evaluate, but we could identify why.",
                comment: "device-authority.failed-with-result"
            )
        case .failedWithoutError:
            return NSLocalizedString(
                "This device failed to evaluate, but no error was thrown.",
                comment: "device-authority.failed-without-error"
            )
        }
    }
}
