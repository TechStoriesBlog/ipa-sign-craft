//
//  FileManager+Copy.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 24/04/26.
//

import Foundation

extension FileManager  {
    func copyWithOverwrite(from source: URL, to destination: URL) throws {
        let fm = FileManager.default

        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }

        try fm.copyItem(at: source, to: destination)
    }
}
