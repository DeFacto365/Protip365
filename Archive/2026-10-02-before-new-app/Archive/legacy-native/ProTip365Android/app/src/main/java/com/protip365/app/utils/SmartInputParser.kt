package com.protip365.app.utils

data class ParsedShiftData(
    val tips: Double? = null,
    val hours: Double? = null,
    val sales: Double? = null
)

object SmartInputParser {
    
    fun parse(input: String): ParsedShiftData {
        val lowerInput = input.lowercase()
        
        return ParsedShiftData(
            tips = extractValue(lowerInput, listOf(
                "made\\s*\\$?(\\d+)".toRegex(),
                "earned\\s*\\$?(\\d+)".toRegex(),
                "\\$?(\\d+)\\s*tips".toRegex()
            )),
            hours = extractValue(lowerInput, listOf(
                "(\\d+\\.?\\d*)\\s*hours".toRegex(),
                "(\\d+\\.?\\d*)\\s*hrs".toRegex(),
                "(\\d+\\.?\\d*)\\s*h".toRegex()
            )),
            sales = extractValue(lowerInput, listOf(
                "on\\s*\\$?(\\d+)".toRegex(),
                "sales\\s*\\$?(\\d+)".toRegex(),
                "\\$?(\\d+)\\s*sales".toRegex()
            ))
        )
    }
    
    private fun extractValue(input: String, patterns: List<Regex>): Double? {
        patterns.forEach { regex ->
            val match = regex.find(input)
            if (match != null && match.groupValues.size > 1) {
                return match.groupValues[1].toDoubleOrNull()
            }
        }
        return null
    }
}
