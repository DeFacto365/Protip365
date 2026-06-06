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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.protip365.app.R
import com.protip365.app.data.local.PreferencesManager
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.presentation.localization.SupportedLanguage
import kotlinx.coroutines.launch

@Composable
fun LanguageSelector(
    modifier: Modifier = Modifier,
    localizationManager: LocalizationManager? = null
) {
@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val preferencesManager = remember { PreferencesManager(context) }
    val manager = localizationManager ?: remember {
        LocalizationManager(context, preferencesManager)
    }

    var showMenu by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val state by manager.state.collectAsState()

    val supportedLanguages = listOf(
        SupportedLanguage.ENGLISH,
        SupportedLanguage.FRENCH,
        SupportedLanguage.SPANISH
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
                contentDescription = manager.getString(R.string.preferred_language),
                modifier = Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = state.currentLanguage.shortCode,
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
            supportedLanguages.forEach { language ->
                DropdownMenuItem(
                    text = {
                        Text(
                            text = language.displayName,
                            fontWeight = if (language == state.currentLanguage) {
                                FontWeight.Bold
                            } else {
                                FontWeight.Normal
                            },
                            color = if (language == state.currentLanguage) {
                                MaterialTheme.colorScheme.primary
                            } else {
                                MaterialTheme.colorScheme.onSurface
                            }
                        )
                    },
                    onClick = {
                        showMenu = false
                        scope.launch {
                            manager.setLanguage(language)
                            // Restart activity to apply language change
                            (context as? android.app.Activity)?.recreate()
                        }
                    }
                )
            }
        }
    }
}