//
// Command.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import ConsoleKit
import Foundation
import ShellOut

@main
enum DeviceAuthorityCommandLine {
    static func main() async throws {
        let console: Console = Terminal()
        let input = CommandInput(arguments: CommandLine.arguments)
        let context = CommandContext(console: console, input: input)

        var commands = AsyncCommands(enableAutocomplete: false)
        commands.use(CreateAuthorityCommand(), as: "create-authority")
        commands.use(CreateLeafCommand(), as: "create-leaf")

        do {
            let group = commands.group(help: "Helps to create the necessary files to secure functionality in your iOS application.")
            try await console.run(group, with: context)
        } catch {
            console.error("\(error)")
            exit(1)
        }
    }
}
