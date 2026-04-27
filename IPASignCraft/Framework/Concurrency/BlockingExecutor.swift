//
//  BlockingExecutor.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 25/04/26.
//

import Foundation


enum BlockingExecutor {
    
    private static let queue = DispatchQueue(
        label: "blocking.executor",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    static func run<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func run(_ work: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try work()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
