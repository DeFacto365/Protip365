import Foundation

struct ParsedShiftData {
    var tips: Double?
    var hours: Double?
    var sales: Double?
}

class SmartInputParser {
    static let shared = SmartInputParser()
    
    private init() {}
    
    func parse(_ input: String) -> ParsedShiftData {
        var data = ParsedShiftData()
        let lowerInput = input.lowercased()
        
        // 1. EXTRACT TIPS (e.g., "made 200", "$200", "200 tips")
        // Regex: (made|earned|tips)?\s*\$?(\d+)
        data.tips = extractValue(from: lowerInput, patterns: [
            "made\\s*\\$?(\\d+)",
            "earned\\s*\\$?(\\d+)",
            "\\$?(\\d+)\\s*tips"
        ])
        
        // 2. EXTRACT HOURS (e.g., "5 hours", "5 hrs", "5h")
        data.hours = extractValue(from: lowerInput, patterns: [
            "(\\d+\\.?\\d*)\\s*hours",
            "(\\d+\\.?\\d*)\\s*hrs",
            "(\\d+\\.?\\d*)\\s*h"
        ])
        
        // 3. EXTRACT SALES (e.g., "on 1000 sales", "sales 1000")
        data.sales = extractValue(from: lowerInput, patterns: [
            "on\\s*\\$?(\\d+)",
            "sales\\s*\\$?(\\d+)",
            "\\$?(\\d+)\\s*sales"
        ])
        
        return data
    }
    
    private func extractValue(from input: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = input as NSString
                let results = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = results.first, match.numberOfRanges > 1 {
                    let numberString = nsString.substring(with: match.range(at: 1))
                    return Double(numberString)
                }
            }
        }
        return nil
    }
}
