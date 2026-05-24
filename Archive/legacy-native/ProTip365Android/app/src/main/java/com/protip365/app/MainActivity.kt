package com.protip365.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
// Predictive back gesture is automatically handled by Compose Navigation
// No additional setup required - NavHost supports predictive back in Android 16+
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.rememberNavController
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.presentation.localization.SupportedLanguage
import com.protip365.app.presentation.navigation.AppNavigation
import com.protip365.app.presentation.navigation.NavigationEventManager
import com.protip365.app.presentation.theme.ProTip365Theme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.datetime.*
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var localizationManager: LocalizationManager

    @Inject
    lateinit var alertManager: com.protip365.app.presentation.alerts.AlertManager

    @Inject
    lateinit var navigationEventManager: NavigationEventManager

    override fun attachBaseContext(newBase: Context) {
        // Apply saved language before activity is created
        val languageCode = runBlocking {
            try {
                (newBase.applicationContext as ProTip365Application)
                    .localizationManager
                    .currentLanguage.code
            } catch (e: Exception) {
                SupportedLanguage.ENGLISH.code
            }
        }

        val context = (newBase.applicationContext as ProTip365Application)
            .localizationManager
            .applyLanguage(newBase, languageCode)
        super.attachBaseContext(context)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        enableEdgeToEdge()

        // Handle notification navigation (iOS-conformant deep linking)
        handleNotificationIntent(intent)

        // Handle app shortcut intents
        handleShortcutIntent(intent)

        setContent {
            ProTip365Theme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ProTip365App()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle notification navigation when app is already running
        handleNotificationIntent(intent)
        // Handle shortcut intents when app is already running
        handleShortcutIntent(intent)
    }

    /**
     * Handle notification tap for deep linking
     * iOS-conformant: Navigates to calendar or shift based on notification data
     */
    private fun handleNotificationIntent(intent: android.content.Intent?) {
        // Use AlertManager to handle notification tap and trigger navigation
        alertManager.handleNotificationTap(intent)
    }

    /**
     * Handle app shortcut intents
     * Navigates to specific screens based on shortcut action
     */
    private fun handleShortcutIntent(intent: Intent?) {
        val data = intent?.data
        if (data?.scheme == "protip365") {
            lifecycleScope.launch {
                when (data.host) {
                    "add_entry" -> {
                        // Navigate to add entry screen
                        val today = Clock.System.now().toLocalDateTime(TimeZone.currentSystemDefault()).date
                        navigationEventManager.navigateToAddEntry(today)
                    }
                    "dashboard" -> {
                        // Navigate to dashboard tab
                        navigationEventManager.navigateToDashboard()
                    }
                    "calendar" -> {
                        // Navigate to calendar tab
                        navigationEventManager.navigateToTab("calendar")
                    }
                }
            }
        }
    }
}

@Composable
fun ProTip365App() {
    val navController = rememberNavController()
    AppNavigation(navController = navController)
}