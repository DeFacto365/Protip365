package com.protip365.app.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Language
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.protip365.app.presentation.localization.LocalizationManager
import kotlinx.coroutines.launch

@Composable
fun LanguageSelector(
    modifier: Modifier = Modifier,
    currentLanguage: String = "en",
    onLanguageSelected: (String) -> Unit = {}
) {
    var showMenu by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    // Language options
    val languages = listOf(
        "en" to "EN",
        "fr" to "FR",
        "es" to "ES"
    )

    Box(modifier = modifier) {
        // Language button matching iOS style
        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(20.dp))
                .background(MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.3f))
                .clickable { showMenu = true }
                .padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Language,
                contentDescription = "Language",
                modifier = Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = languages.find { it.first == currentLanguage }?.second ?: "EN",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.primary
            )
        }

        // Dropdown menu
        DropdownMenu(
            expanded = showMenu,
            onDismissRequest = { showMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text("English") },
                onClick = {
                    showMenu = false
                    onLanguageSelected("en")
                }
            )
            DropdownMenuItem(
                text = { Text("Français") },
                onClick = {
                    showMenu = false
                    onLanguageSelected("fr")
                }
            )
            DropdownMenuItem(
                text = { Text("Español") },
                onClick = {
                    showMenu = false
                    onLanguageSelected("es")
                }
            )
        }
    }
}