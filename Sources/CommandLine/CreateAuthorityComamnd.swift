//
// CreateAuthorityComamnd.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import ConsoleKit
import Foundation
import ShellOut

struct CreateAuthorityCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Creates a new certificate authority, and mobile configuration profile"
    }

    func run(using context: CommandContext, signature _: Signature) async throws {
        context.console.output("Welcome to the " + "Device Authority".consoleText(.success) + " command-line tool.\n")

        // NAME
        context.console.output(
            "Profile Name".consoleText(isBold: true) + .newLine +
                "This will be visible within iOS system settings.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.warning),
            newLine: false
        )

        var name = context.console.input()

        if name.isEmpty {
            name = "Swift Device Authority"
            context.console.warning("No input given, using default: '\(name)'")
        }

        // DESCRIPTION

        context.console.output(
            "\nProfile Description".consoleText(isBold: true) + .newLine +
                "This will be visible within iOS system settings.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.info),
            newLine: false
        )

        let description = context.console.input()

        if description.isEmpty {
            context.console.warning("No input given, description will be empty")
        }

        // ORGANISATION

        context.console.output(
            "\nOrganisation Name".consoleText(isBold: true) + .newLine +
                "This will be embedded within the certificate.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.info),
            newLine: false
        )

        let organisation = context.console.input()

        if organisation.isEmpty {
            context.console.warning("No input given, organisation will be empty")
        }

        // PASSWORD

        context.console.output(
            "\nCertificate Password".consoleText(isBold: true) + .newLine +
                "This will be needed in order to generate Leaf certificates.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.error),
            newLine: false
        )

        var failCount = 0
        var password: String?

        while password == nil {
            let tempPassword = context.console.input(isSecure: true)

            guard tempPassword.count >= 6 else {
                context.console.clear(lines: failCount == 0 ? 1 : 2)
                let exasperationString = failCount == 0 ? "." : String(repeating: "!", count: failCount)
                context.console.error("Input must be at least 6 character long\(exasperationString)")
                context.console.error("> ", newLine: false)
                failCount += 1
                continue
            }

            password = tempPassword
        }

        // DAYS

        context.console.output(
            "\nCertificate Validity Duration".consoleText(isBold: true) + .newLine +
                "The number of days in which the certificate will be valid for.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.warning),
            newLine: false
        )

        var daysInput = context.console.input()

        if daysInput.isEmpty {
            daysInput = "3650"
            context.console.warning("No input given, using default: \(daysInput) (10 years)")
        }

        guard let days = Int(daysInput) else {
            context.console.error("Input ('\(daysInput)') is not a valid integer number.")
            exit(1)
        }

        guard days >= 1 else {
            context.console.error("Input (\(days)) must be at least 1.")
            exit(1)
        }

        // VERIFY

        // TODO: summarise inputs for user to confirm before generating files
        guard context.console.confirm("\nAre you sure?") else {
            context.console.error("Failed to verify, stopping...")
            exit(1)
        }

        // STEPS

        // Create key

        context.console.info("\nCreating a unique RSA private key with your chosen password")
        try shellOut(to: "openssl genrsa -aes256 -out SwiftDeviceAuthority.key 4096 -passout pass:\(password!)")
        context.console.success("Completed")

        // Create authority
        context.console.info("\nCreating new Certificate Authority using generated key")

        let subject = [
            "CN": name,
            "O": organisation,
        ]
        .filter { !$0.value.isEmpty } // filter empty items
        .map { $0.key + "=" + $0.value } // key=value
        .joined(separator: "/")

        try shellOut(to: [
            "openssl req -x509 -new -nodes",
            "-key SwiftDeviceAuthority.key",
            "-sha256",
            "-days \(days)",
            "-out SwiftDeviceAuthority.cer",
            "-subj '/\(subject)'",
            "-passin pass:\(password!)",
        ].joined(separator: " "))
        context.console.success("Completed")

        // Write file
        context.console.info("\nCreating mobile configuration profile with new authority")
        let outputPath = URL(fileURLWithPath: "SwiftDeviceAuthority.mobileconfig")
        try MobileConfigurationExporter(
            name: name,
            abstract: description,
            organisation: organisation,
            file: "SwiftDeviceAuthority.cer"
        ).export().write(to: outputPath)
        context.console.success("Completed")

        let outputDirectory = outputPath.deletingLastPathComponent().absoluteString.replacingOccurrences(of: "file://", with: "")
        context.console.success("\nSaved SwiftDeviceAuthority files to \(outputDirectory)")
    }
}
