package com.protip365.app

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
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
import com.protip365.app.presentation.theme.ProTip365Theme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var localizationManager: LocalizationManager

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
}

@Composable
fun ProTip365App() {
    val navController = rememberNavController()
    AppNavigation(navController = navController)
}