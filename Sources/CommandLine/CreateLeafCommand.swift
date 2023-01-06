//
// CreateLeafCommand.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import ConsoleKit
import Foundation
import ShellOut

struct CreateLeafCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    var help: String {
        "Creates a new leaf certificate"
    }

    func run(using context: CommandContext, signature _: Signature) async throws {
        // TODO: lots of input-duplication with CreateAuthorityCommand, how can we reuse?
        
        context.console.output("Welcome to the " + "Device Authority".consoleText(.success) + " command-line tool.\n")

        // NAME
        context.console.output(
            "Certificate Name".consoleText(isBold: true) + .newLine +
                "This will be embedded within the certificate.".consoleText(.info) + .newLine +
                .newLine +
                "> ".consoleText(.warning),
            newLine: false
        )

        var name = context.console.input()

        if name.isEmpty {
            name = "Swift Device Authority"
            context.console.warning("No input given, using default: '\(name)'")
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
                "This must match the one used to generate the Certificate Authority (CA).".consoleText(.info) + .newLine +
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

        // Create Leaf
        context.console.info("\nCreating a new Leaf certificate")
        
        let subject = [
            "CN": name,
            "O": organisation,
        ]
        .filter { !$0.value.isEmpty } // filter empty items
        .map { $0.key + "=" + $0.value } // key=value
        .joined(separator: "/")
        
        try shellOut(to: [
            "openssl req -new -nodes",
            "-out SwiftDeviceAuthority-Leaf.csr",
            "-newkey rsa:4096",
            "-keyout SwiftDeviceAuthority-Leaf.key",
            "-subj '/\(subject)'",
        ].joined(separator: " "))
        context.console.success("Completed")

        // Sign Leaf
        context.console.info("\nSigning Leaf certificate using Root CA")

        try shellOut(to: [
            "openssl x509 -req",
            "-in SwiftDeviceAuthority-Leaf.csr",
            "-CA SwiftDeviceAuthority.crt",
            "-CAkey SwiftDeviceAuthority.key",
            "-CAcreateserial",
            "-out SwiftDeviceAuthority-Leaf.cer",
            "-outform DER",
            "-days \(days)",
            "-sha256",
            "-passin pass:\(password!)",
        ].joined(separator: " "))
        context.console.success("Completed")
    }
}
