package com.protip365.app.domain.repository

import com.protip365.app.data.models.SubscriptionTier
import com.protip365.app.data.models.UserSubscription
import kotlinx.coroutines.flow.Flow

interface SubscriptionRepository {
    suspend fun getCurrentSubscription(userId: String? = null): UserSubscription?
    suspend fun purchaseSubscription(tier: SubscriptionTier): Result<Unit>
    suspend fun restorePurchases(): Result<Unit>
    suspend fun cancelSubscription(): Result<Unit>
    fun observeSubscriptionStatus(): Flow<SubscriptionTier>
    suspend fun checkWeeklyLimits(userId: String): WeeklyLimits
    suspend fun startFreeTrial(tier: String): Result<Unit>
    suspend fun initializeFree(): Result<Unit>
}

data class WeeklyLimits(
    val shiftsUsed: Int,
    val entriesUsed: Int,
    val shiftsLimit: Int?,
    val entriesLimit: Int?,
    val canAddShift: Boolean,
    val canAddEntry: Boolean
)