//
//  ShellExecutor.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 17/03/26.
//

import Foundation

struct ShellExecutor {
    
    static func run(_ command: String) throws {
        let result = try runWithOutput(command)
        
        if result.status != 0 {
            throw NSError(
                domain: "ShellError",
                code: Int(result.status),
                userInfo: [NSLocalizedDescriptionKey: result.output]
            )
        }
    }
    
    static func runWithOutput(_ command: String) throws -> ShellResult {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["bash", "-c", command]
        
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = NSHomeDirectoryForUser(NSUserName()) ?? env["HOME"]
        env["USER"] = NSUserName()
        env["LOGNAME"] = NSUserName()
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
        
        process.environment = env
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return ShellResult(
            output: output,
            status: process.terminationStatus
        )
    }
}

struct ShellResult {
    let output: String
    let status: Int32
}
