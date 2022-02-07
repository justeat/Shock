//
//  String+PathMatching.swift
//  Shock
//
//  Created by Alberto De Bortoli on 07/02/2022.
//  Copyright © 2022 Just Eat. All rights reserved.
//

import Foundation

extension String {
    
    func pathMatches(_ other: String) -> Bool {
        pathMatches(other, tokenPrefix: ":") || pathMatches(other, tokenPrefix: "{")
    }
    
    private func pathMatches(_ other: String, tokenPrefix: Character) -> Bool {
        let bothTemplates = self.contains() { $0 == tokenPrefix } && other.contains() { $0 == tokenPrefix }
        let parts = self.split(separator: "/")
        let otherParts = other.split(separator: "/")
        guard parts.count == otherParts.count else { return false }
        var match = true
        for (index, part) in parts.enumerated() {
            let otherPart = otherParts[index]
            if !bothTemplates {
                if part.hasPrefix(String(tokenPrefix)) {
                    continue
                }
                if otherPart.hasPrefix(String(tokenPrefix)) {
                    continue
                }
            }
            match = part.lowercased() == otherPart.lowercased()
            if !match {
                break
            }
        }
        return match
    }
}
