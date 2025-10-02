package com.protip365.app.presentation.dashboard

/**
 * Performance targets for the dashboard performance card
 */
data class PerformanceTargets(
    val hours: Double = 0.0,
    val tips: Double = 0.0,
    val sales: Double = 0.0,
    val tipPercentage: Double = 0.0
)

/**
 * Individual metric performance data
 */
data class MetricPerformance(
    val name: String,
    val actual: Double,
    val target: Double,
    val percentage: Double,
    val isCurrency: Boolean,
    val suffix: String = ""
)
