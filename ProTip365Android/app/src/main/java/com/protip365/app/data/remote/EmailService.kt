package com.protip365.app.data.remote

import kotlinx.serialization.Serializable
import javax.inject.Inject
import javax.inject.Singleton

@Serializable
data class SuggestionRequest(
    val suggestion: String
)

@Serializable
data class SupportRequest(
    val subject: String,
    val message: String
)

@Serializable
data class EmailResponse(
    val success: Boolean,
    val error: String? = null
)

@Singleton
class EmailService @Inject constructor() {
    
    suspend fun sendSuggestion(suggestion: String): Result<EmailResponse> {
        return try {
            // TODO: Implement actual Supabase function call
            Result.success(EmailResponse(success = true))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun sendSupportRequest(subject: String, message: String): Result<EmailResponse> {
        return try {
            // TODO: Implement actual Supabase function call
            Result.success(EmailResponse(success = true))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
