package com.protip365.app.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import com.protip365.app.data.remote.SupabaseClient
import com.protip365.app.data.remote.supabaseClient
import com.protip365.app.data.remote.EmailService
import com.protip365.app.data.repository.*
import com.protip365.app.domain.repository.*
import com.protip365.app.data.models.SubscriptionTier
import com.protip365.app.data.models.UserSubscription
import com.protip365.app.presentation.localization.LocalizationManager
import com.protip365.app.presentation.security.SecurityManager
import com.protip365.app.presentation.alerts.AlertManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
// import com.protip365.app.presentation.export.ExportManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import io.github.jan.supabase.SupabaseClient as JanSupabaseClient
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "protip365_preferences")

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideJanSupabaseClient(): JanSupabaseClient = supabaseClient

    @Provides
    @Singleton
    fun provideSupabaseClient(): SupabaseClient = SupabaseClient()

    @Provides
    @Singleton
    fun provideDataStore(
        @ApplicationContext context: Context
    ): DataStore<Preferences> = context.dataStore

    @Provides
    @Singleton
    fun provideAuthRepository(
        janSupabaseClient: JanSupabaseClient,
        dataStore: DataStore<Preferences>
    ): AuthRepository = AuthRepositoryImpl(janSupabaseClient, dataStore)

    @Provides
    @Singleton
    fun provideUserRepository(
        @ApplicationContext context: Context,
        janSupabaseClient: JanSupabaseClient
    ): UserRepository = UserRepositoryImpl(janSupabaseClient, context)


    // New simplified repositories
    @Provides
    @Singleton
    fun provideExpectedShiftRepository(
        janSupabaseClient: JanSupabaseClient
    ): ExpectedShiftRepository = ExpectedShiftRepositoryImpl(janSupabaseClient)

    @Provides
    @Singleton
    fun provideShiftEntryRepository(
        janSupabaseClient: JanSupabaseClient
    ): ShiftEntryRepository = ShiftEntryRepositoryImpl(janSupabaseClient)

    @Provides
    @Singleton
    fun provideCompletedShiftRepository(
        expectedShiftRepository: ExpectedShiftRepository,
        shiftEntryRepository: ShiftEntryRepository,
        employerRepository: EmployerRepository
    ): CompletedShiftRepository = CompletedShiftRepositoryImpl(
        expectedShiftRepository,
        shiftEntryRepository,
        employerRepository
    )

    @Provides
    @Singleton
    fun provideEmployerRepository(
        janSupabaseClient: JanSupabaseClient
    ): EmployerRepository = EmployerRepositoryImpl(janSupabaseClient)

    // Subscription repository - using real implementation from BillingModule
    // (Removed mock implementation to avoid duplicate binding)

    @Provides
    @Singleton
    fun provideAlertRepository(
        supabaseClient: SupabaseClient
    ): AlertRepository = AlertRepositoryImpl(supabaseClient)

    @Provides
    @Singleton
    fun provideAchievementRepository(
        janSupabaseClient: JanSupabaseClient
    ): AchievementRepository = AchievementRepositoryImpl(janSupabaseClient)

    @Provides
    @Singleton
    fun provideEmailService(
        supabaseClient: SupabaseClient
    ): EmailService = EmailService(supabaseClient)

    @Provides
    @Singleton
    fun providePreferencesManager(
        @ApplicationContext context: Context
    ): com.protip365.app.data.local.PreferencesManager =
        com.protip365.app.data.local.PreferencesManager(context)

    @Provides
    @Singleton
    fun provideLocalizationManager(
        @ApplicationContext context: Context,
        preferencesManager: com.protip365.app.data.local.PreferencesManager
    ): LocalizationManager = LocalizationManager(context, preferencesManager)

    @Provides
    @Singleton
    fun provideSecurityManager(
        @ApplicationContext context: Context
    ): SecurityManager = SecurityManager(context)

    @Provides
    @Singleton
    fun provideSecurityRepository(
        @ApplicationContext context: Context,
        securityManager: SecurityManager
    ): SecurityRepository = SecurityRepositoryImpl(context, securityManager)

    @Provides
    @Singleton
    fun provideAlertManager(
        @ApplicationContext context: Context,
        alertRepository: AlertRepository,
        preferencesManager: com.protip365.app.data.local.PreferencesManager
    ): AlertManager = AlertManager(context, alertRepository, preferencesManager)

    // @Provides
    // @Singleton
    // fun provideExportManager(): ExportManager = ExportManager()
}