package com.protip365.app.presentation.localization

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BaseLocalization @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    companion object {
        private val LANGUAGE_KEY = stringPreferencesKey("language")
    }

    suspend fun setLanguage(language: String) {
        dataStore.edit { preferences ->
            preferences[LANGUAGE_KEY] = language
        }
    }

    fun getLanguage(): Flow<String> {
        return dataStore.data.map { preferences ->
            preferences[LANGUAGE_KEY] ?: "en"
        }
    }

    fun getLanguageSync(): String {
        return "en" // Default for now, will be improved with proper sync
    }
}


