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

    func run(using _: CommandContext, signature _: Signature) async throws {
        print("soon")
    }
}
