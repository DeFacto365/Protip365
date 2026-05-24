package com.protip365.app

import android.app.Application
// import com.google.firebase.FirebaseApp
// import com.google.firebase.crashlytics.ktx.crashlytics
// import com.google.firebase.ktx.Firebase
// import com.protip365.app.presentation.analytics.AnalyticsManager
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.utils.PerformanceProfiler
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class ProTip365Application : Application() {

    @Inject
    lateinit var localizationManager: LocalizationManager

    // @Inject
    // lateinit var analyticsManager: AnalyticsManager

    private lateinit var appProfiler: PerformanceProfiler

    override fun onCreate() {
        super.onCreate()

        // Initialize performance profiler for system-triggered profiling
        appProfiler = PerformanceProfiler(this)
        appProfiler.registerProfilingInterest()

        // Firebase temporarily disabled for testing
        // Initialize Firebase
        // FirebaseApp.initializeApp(this)

        // Set up Crashlytics
        // setupCrashlytics()

        // Log app startup
        // analyticsManager.logAppStartupTime(System.currentTimeMillis())
    }

    /*
    private fun setupCrashlytics() {
        val crashlytics = Firebase.crashlytics

        // Set custom keys for better crash context
        crashlytics.setCustomKey("app_version", BuildConfig.VERSION_NAME)
        crashlytics.setCustomKey("app_version_code", BuildConfig.VERSION_CODE)
        crashlytics.setCustomKey("build_type", BuildConfig.BUILD_TYPE)

        // Set up custom uncaught exception handler
        Thread.setDefaultUncaughtExceptionHandler { thread, exception ->
            crashlytics.recordException(exception)
            crashlytics.log("Uncaught exception on thread: ${thread.name}")

            // Call the default handler to ensure app closes properly
            Thread.getDefaultUncaughtExceptionHandler()?.uncaughtException(thread, exception)
        }
    }
    */
}