package com.protip365.app.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material.icons.filled.ArrowUpward
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberBottom
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberStart
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberColumnCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.core.cartesian.axis.HorizontalAxis
import com.patrykandpatrick.vico.core.cartesian.axis.VerticalAxis
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.CartesianValueFormatter
import com.patrykandpatrick.vico.core.cartesian.data.columnSeries

@Composable
fun EarningsChart(
    weeklyData: List<Pair<String, Double>>, // Day label, Amount
    totalForWeek: String
) {
    // Vico Chart Setup
    // Model producer is now created inside the CartesianChartHost setup or remembered separately


    // Colors
    val barColor = MaterialTheme.colorScheme.primary
    val barGradient = Brush.verticalGradient(
        colors = listOf(
            barColor.copy(alpha = 0.8f),
            barColor.copy(alpha = 0.4f)
        )
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp)
            .background(
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
                RoundedCornerShape(20.dp)
            )
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "WEEKLY TREND",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = totalForWeek,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                )
            }
            
            // Mock Trend Indicator
            Surface(
                color = Color.Green.copy(alpha = 0.2f),
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                     Icon(
                        imageVector = androidx.compose.material.icons.Icons.Default.ArrowUpward,
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = Color(0xFF006400) // Dark Green
                    )
                    Text(
                        text = "12%",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color(0xFF006400),
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Chart
        // Chart
        val modelProducer = remember(weeklyData) { CartesianChartModelProducer() }
        
        LaunchedEffect(weeklyData) {
            modelProducer.runTransaction {
                columnSeries {
                    series(weeklyData.map { it.second })
                }
            }
        }

        CartesianChartHost(
            chart = rememberCartesianChart(
                rememberColumnCartesianLayer(),
                startAxis = VerticalAxis.rememberStart(),
                bottomAxis = HorizontalAxis.rememberBottom(
                    // valueFormatter = CartesianValueFormatter { _, value, _ -> (weeklyData.getOrNull(value.toInt())?.first ?: "").subSequence(0, 3) }
                ),
            ),
            modelProducer = modelProducer,
            modifier = Modifier.height(180.dp)
        )
    }
}
