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

    @Provides
    @Singleton
    fun provideShiftRepository(
        janSupabaseClient: JanSupabaseClient
    ): ShiftRepository = ShiftRepositoryImpl(janSupabaseClient)

    @Provides
    @Singleton
    fun provideEmployerRepository(
        janSupabaseClient: JanSupabaseClient
    ): EmployerRepository = EmployerRepositoryImpl(janSupabaseClient)

    // Subscription repository disabled for testing - providing mock implementation
    @Provides
    @Singleton
    fun provideSubscriptionRepository(): SubscriptionRepository = object : SubscriptionRepository {
        override suspend fun getCurrentSubscription(userId: String?): UserSubscription? = null
        override suspend fun purchaseSubscription(tier: SubscriptionTier): Result<Unit> = Result.success(Unit)
        override suspend fun restorePurchases(): Result<Unit> = Result.success(Unit)
        override suspend fun cancelSubscription(): Result<Unit> = Result.success(Unit)
        override fun observeSubscriptionStatus(): Flow<SubscriptionTier> = flowOf(SubscriptionTier.FULL_ACCESS)
        override suspend fun checkWeeklyLimits(userId: String): WeeklyLimits = WeeklyLimits(
            shiftsUsed = 0,
            entriesUsed = 0,
            shiftsLimit = null,
            entriesLimit = null,
            canAddShift = true,
            canAddEntry = true
        )
        override suspend fun startFreeTrial(tier: String): Result<Unit> = Result.success(Unit)
        override suspend fun initializeFree(): Result<Unit> = Result.success(Unit)
    }

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
    fun provideEmailService(): EmailService = EmailService()

    @Provides
    @Singleton
    fun provideLocalizationManager(): LocalizationManager = LocalizationManager()

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

    // @Provides
    // @Singleton
    // fun provideExportManager(): ExportManager = ExportManager()
}