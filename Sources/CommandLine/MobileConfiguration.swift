//
// MobileConfiguration.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import Foundation
import ShellOut

struct MobileConfigurationExporter {
    let name: String
    let abstract: String
    let organisation: String
    let file: String

    func export() throws -> Data {
        guard let certificateFileData = FileManager.default.contents(atPath: file) else {
            fatalError()
        }

        let certificateFileString = String(decoding: certificateFileData, as: UTF8.self)
            .components(separatedBy: .newlines)
            .dropFirst()
            .dropLast(2)
            .joined(separator: "\n")

        guard let certificateData = Data(base64Encoded: certificateFileString, options: .ignoreUnknownCharacters) else {
            fatalError()
        }

        let config = MobileConfiguration(
            name: name,
            abstract: abstract,
            organisation: organisation,
            certificate: certificateData
        )

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        return try encoder.encode(config)
    }
}

struct MobileConfiguration: Encodable {
    enum CodingKeys: String, CodingKey {
        case content = "PayloadContent"
        case description = "PayloadDescription"
        case displayName = "PayloadDisplayName"
        case identifier = "PayloadIdentifier"
        case organization = "PayloadOrganization"
        case removalDisallowed = "PayloadRemovalDisallowed"
        case type = "PayloadType"
        case uuid = "PayloadUUID"
        case version = "PayloadVersion"
    }

    let content: [MobileConfigurationCertificate]
    let description: String
    let displayName: String
    let identifier: String
    let organization: String
    let removalDisallowed: Bool
    let type: String
    let uuid: String
    let version: Int

    init(name: String, abstract: String, organisation: String, certificate: Data) {
        let uniqueId = UUID().uuidString

        content = [.init(certificate: certificate)]
        description = abstract
        displayName = name
        identifier = "sidetrack.device-authority.\(uniqueId)"
        organization = organisation
        removalDisallowed = false
        type = "Configuration"
        uuid = uniqueId
        version = 1
    }
}

struct MobileConfigurationCertificate: Encodable {
    enum CodingKeys: String, CodingKey {
        case fileName = "PayloadCertificateFileName"
        case content = "PayloadContent"
        case description = "PayloadDescription"
        case displayName = "PayloadDisplayName"
        case identifier = "PayloadIdentifier"
        case type = "PayloadType"
        case uuid = "PayloadUUID"
        case version = "PayloadVersion"
    }

    let fileName: String
    let content: Data
    let description: String
    let displayName: String
    let identifier: String
    let type: String
    let uuid: String
    let version: Int

    init(certificate: Data) {
        let uniqueId = UUID().uuidString

        fileName = "DeviceAuthority.cer"
        content = certificate
        description = "Adds a CA root certificate"
        displayName = "Swift Device Authority"
        identifier = "com.apple.security.root.\(uniqueId)"
        type = "com.apple.security.root"
        uuid = uniqueId
        version = 1
    }
}
