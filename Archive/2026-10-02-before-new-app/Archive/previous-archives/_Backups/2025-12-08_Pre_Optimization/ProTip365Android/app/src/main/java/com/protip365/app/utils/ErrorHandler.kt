package com.protip365.app.utils

import android.content.Context
import android.util.Log
import android.widget.Toast
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.res.stringResource
import com.protip365.app.R

/**
 * Global error handler for the ProTip365 app
 * Shows user-friendly error messages instead of crashing silently
 */
object ErrorHandler {

    private const val TAG = "ProTip365Error"

    /**
     * Handle navigation errors gracefully
     */
    fun handleNavigationError(context: Context, route: String, error: Exception) {
        Log.e(TAG, "Navigation error to route: $route", error)

        Toast.makeText(
            context,
            "Navigation error: Unable to open ${route.split("/").first()}. Please try again.",
            Toast.LENGTH_LONG
        ).show()
    }

    /**
     * Handle general errors with user-friendly messages
     */
    fun handleError(context: Context, error: Exception, userMessage: String? = null) {
        Log.e(TAG, "Error occurred: ${error.message}", error)

        val message = userMessage ?: when (error) {
            is IllegalArgumentException -> "Invalid data: ${error.message}"
            is NullPointerException -> "Missing required information. Please try again."
            is IllegalStateException -> "The app is in an invalid state. Please restart."
            else -> "An unexpected error occurred. Please try again."
        }

        Toast.makeText(context, message, Toast.LENGTH_LONG).show()
    }

    /**
     * Log error without showing to user (for non-critical errors)
     */
    fun logError(tag: String, message: String, error: Exception? = null) {
        if (error != null) {
            Log.e(TAG, "[$tag] $message", error)
        } else {
            Log.e(TAG, "[$tag] $message")
        }
    }
}

/**
 * Composable error dialog for showing errors in UI
 */
@Composable
fun ErrorDialog(
    error: Exception?,
    onDismiss: () -> Unit
) {
    if (error != null) {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text("Error") },
            text = {
                Text(
                    when (error) {
                        is IllegalArgumentException -> "Invalid data provided. Please check your input."
                        is NullPointerException -> "Missing required information. Please try again."
                        is IllegalStateException -> "The app encountered an unexpected state. Please restart the app."
                        else -> error.message ?: "An unexpected error occurred. Please try again."
                    }
                )
            },
            confirmButton = {
                TextButton(onClick = onDismiss) {
                    Text("OK")
                }
            }
        )
    }
}

/**
 * Extension function to safely navigate with error handling
 */
fun androidx.navigation.NavController.safeNavigate(
    route: String,
    onError: ((Exception) -> Unit)? = null
) {
    try {
        navigate(route)
    } catch (e: Exception) {
        onError?.invoke(e) ?: run {
            Log.e("NavError", "Failed to navigate to: $route", e)
        }
    }
}
