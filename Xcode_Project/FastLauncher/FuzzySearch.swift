import Foundation

struct FuzzySearch {
    private static func normalize(_ s: String) -> String {
        // Only lowercase and trim the ends.
        // DO NOT remove spaces, underscores, or version numbers anymore.
        return s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func score(query: String, target: String) -> Int? {
        let q = normalize(query)
        let t = normalize(target)

        if q.isEmpty { return 1000 }

        // 1. Direct Substring Match
        if t.contains(q) {
            var score = 1000 - (t.count - q.count)
            if t.hasPrefix(q) { score += 500 }
            return score
        }

        // 2. Fuzzy Match with Separator Awareness
        let qChars = Array(q)
        let tChars = Array(t)
        var qi = 0
        var score = 0
        var lastMatchIndex = 0

        for (i, char) in tChars.enumerated() {
            guard qi < qChars.count else { break }
            
            let queryChar = qChars[qi]
            let targetChar = char
            
            // ✨ IMPROVED MATCH LOGIC:
            // Match if characters are identical OR
            // if user typed a space and target has a separator.
            let isSeparatorMatch = queryChar == " " && (targetChar == "_" || targetChar == "." || targetChar == "-")
            
            if targetChar == queryChar || isSeparatorMatch {
                let gap = i - lastMatchIndex
                var charScore = max(1, 20 - gap)
                
                // Word Boundary Bonus
                if qi == 0 || (qi > 0 && qChars[qi-1] == " ") {
                    if i == 0 {
                        charScore += 500
                    } else {
                        let prev = tChars[i-1]
                        if prev == " " || prev == "_" || prev == "-" || prev == "." {
                            charScore += 400
                        }
                    }
                }

                score += charScore
                lastMatchIndex = i
                qi += 1
            }
        }

        guard qi == qChars.count else { return nil }
        return score
    }
}
