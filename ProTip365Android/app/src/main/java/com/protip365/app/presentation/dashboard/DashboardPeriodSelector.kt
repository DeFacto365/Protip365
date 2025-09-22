package com.protip365.app.presentation.dashboard

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun DashboardPeriodSelector(
    selectedPeriod: Int,
    monthViewType: Int,
    onPeriodSelected: (Int) -> Unit,
    onMonthViewTypeChanged: (Int) -> Unit,
    currentLanguage: String = "en"
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        // Period tabs (Today, Week, Month, Year)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(4.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                PeriodTab(
                    text = when (currentLanguage) {
                        "fr" -> "Aujourd'hui"
                        "es" -> "Hoy"
                        else -> "Today"
                    },
                    isSelected = selectedPeriod == 0,
                    onClick = { onPeriodSelected(0) },
                    modifier = Modifier.weight(1f)
                )
                PeriodTab(
                    text = when (currentLanguage) {
                        "fr" -> "Semaine"
                        "es" -> "Semana"
                        else -> "Week"
                    },
                    isSelected = selectedPeriod == 1,
                    onClick = { onPeriodSelected(1) },
                    modifier = Modifier.weight(1f)
                )
                PeriodTab(
                    text = when (currentLanguage) {
                        "fr" -> "Mois"
                        "es" -> "Mes"
                        else -> "Month"
                    },
                    isSelected = selectedPeriod == 2,
                    onClick = { onPeriodSelected(2) },
                    modifier = Modifier.weight(1f)
                )
                PeriodTab(
                    text = when (currentLanguage) {
                        "fr" -> "Année"
                        "es" -> "Año"
                        else -> "Year"
                    },
                    isSelected = selectedPeriod == 3,
                    onClick = { onPeriodSelected(3) },
                    modifier = Modifier.weight(1f)
                )
            }
        }

        // Month view type selector (only visible when Month is selected)
        if (selectedPeriod == 2) {
            Spacer(modifier = Modifier.height(8.dp))
            MonthViewTypeSelector(
                monthViewType = monthViewType,
                onViewTypeChanged = onMonthViewTypeChanged,
                currentLanguage = currentLanguage
            )
        }
    }
}

@Composable
private fun PeriodTab(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(
                if (isSelected) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.surface
            )
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
            color = if (isSelected) MaterialTheme.colorScheme.onPrimary
            else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun MonthViewTypeSelector(
    monthViewType: Int,
    onViewTypeChanged: (Int) -> Unit,
    currentLanguage: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.3f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(4.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            MonthViewTab(
                text = when (currentLanguage) {
                    "fr" -> "Mois calendaire"
                    "es" -> "Mes calendario"
                    else -> "Calendar Month"
                },
                isSelected = monthViewType == 0,
                onClick = { onViewTypeChanged(0) },
                modifier = Modifier.weight(1f)
            )
            MonthViewTab(
                text = when (currentLanguage) {
                    "fr" -> "4 semaines"
                    "es" -> "4 semanas"
                    else -> "4 Weeks Pay"
                },
                isSelected = monthViewType == 1,
                onClick = { onViewTypeChanged(1) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun MonthViewTab(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(
                if (isSelected) MaterialTheme.colorScheme.secondary
                else MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.3f)
            )
            .clickable { onClick() }
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal,
            color = if (isSelected) MaterialTheme.colorScheme.onSecondary
            else MaterialTheme.colorScheme.onSecondaryContainer
        )
    }
}