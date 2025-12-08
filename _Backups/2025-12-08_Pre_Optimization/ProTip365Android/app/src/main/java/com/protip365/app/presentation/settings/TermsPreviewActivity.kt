package com.protip365.app.presentation.settings

import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.navigation.compose.rememberNavController
import com.protip365.app.presentation.theme.ProTip365Theme
import java.util.Locale

/**
 * Preview activity to test Terms and Conditions in different languages
 * This is for testing purposes only
 */
class TermsPreviewActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            ProTip365Theme {
                TermsPreviewScreen()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsPreviewScreen() {
    var currentLanguage by remember { mutableStateOf("en") }
@Suppress("UNUSED_VARIABLE")
    val context = LocalContext.current
    val navController = rememberNavController()

    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Language Selector
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Button(
                    onClick = {
                        currentLanguage = "en"
                        updateLocale(context, "en")
                    },
                    colors = if (currentLanguage == "en")
                        ButtonDefaults.buttonColors()
                    else
                        ButtonDefaults.outlinedButtonColors()
                ) {
                    Text("English")
                }

                Button(
                    onClick = {
                        currentLanguage = "fr"
                        updateLocale(context, "fr")
                    },
                    colors = if (currentLanguage == "fr")
                        ButtonDefaults.buttonColors()
                    else
                        ButtonDefaults.outlinedButtonColors()
                ) {
                    Text("Français")
                }

                Button(
                    onClick = {
                        currentLanguage = "es"
                        updateLocale(context, "es")
                    },
                    colors = if (currentLanguage == "es")
                        ButtonDefaults.buttonColors()
                    else
                        ButtonDefaults.outlinedButtonColors()
                ) {
                    Text("Español")
                }
            }
        }

        // Terms and Conditions Screen
        Box(modifier = Modifier.weight(1f)) {
            TermsAndConditionsScreen(navController = navController)
        }
    }
}

private fun updateLocale(context: Context, languageCode: String) {
    val locale = Locale(languageCode)
    Locale.setDefault(locale)
    val config = Configuration(context.resources.configuration)
    config.setLocale(locale)
    context.resources.updateConfiguration(config, context.resources.displayMetrics)
}