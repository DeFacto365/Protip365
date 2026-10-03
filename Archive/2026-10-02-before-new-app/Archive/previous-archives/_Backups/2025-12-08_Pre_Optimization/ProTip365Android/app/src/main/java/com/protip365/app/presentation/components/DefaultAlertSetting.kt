package com.protip365.app.presentation.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.NotificationImportant
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.protip365.app.R
import com.protip365.app.presentation.localization.LocalizedText

@Composable
fun DefaultAlertSetting(
    defaultAlert: String,
    onDefaultAlertChanged: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }

    val alertOptions = listOf(
        "None" to stringResource(R.string.alert_none),
        "15" to stringResource(R.string.alert_15_minutes),
        "30" to stringResource(R.string.alert_30_minutes),
        "60" to stringResource(R.string.alert_60_minutes),
        "1440" to stringResource(R.string.alert_1_day)
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded }
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = Icons.Default.NotificationImportant,
                contentDescription = null
            )
            Text(stringResource(R.string.default_alert_label))
        }

               TextButton(onClick = { expanded = !expanded }) {
                   Text(
                       when (defaultAlert) {
                           "None" -> LocalizedText("alert_none")
                           "15" -> LocalizedText("alert_15_minutes")
                           "30" -> LocalizedText("alert_30_minutes")
                           "60" -> LocalizedText("alert_60_minutes")
                           "1440" -> LocalizedText("alert_1_day")
                           else -> LocalizedText("alert_none")
                       }
                   )
               }
    }

    DropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        alertOptions.forEach { (value, label) ->
            DropdownMenuItem(
                text = { Text(label) },
                onClick = {
                    onDefaultAlertChanged(value)
                    expanded = false
                }
            )
        }
    }
}
