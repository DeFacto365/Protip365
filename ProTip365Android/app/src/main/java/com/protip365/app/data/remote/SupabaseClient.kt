package com.protip365.app.data.remote

import io.github.jan.supabase.SupabaseClient as JanSupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.gotrue.auth
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.storage.Storage
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.*
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

object SupabaseConfig {
    const val SUPABASE_URL = "https://ztzpjsbfzcccvbacgskc.supabase.co"
    const val SUPABASE_ANON_KEY = "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
}

val supabaseClient = createSupabaseClient(
    supabaseUrl = SupabaseConfig.SUPABASE_URL,
    supabaseKey = SupabaseConfig.SUPABASE_ANON_KEY
) {
    install(Auth) {
        alwaysAutoRefresh = true
        autoLoadFromStorage = true
    }
    install(Postgrest) {
        // Configure Postgrest if needed
    }
    install(Realtime) {
        // Configure Realtime if needed
    }
    install(Storage) {
        // Configure Storage if needed
    }

    httpEngine = Android.create {
        connectTimeout = 10_000
        socketTimeout = 10_000
    }
}

@Singleton
class SupabaseClient @Inject constructor() {
    val client: JanSupabaseClient = supabaseClient

    fun getCurrentUserId(): String? {
        return client.auth.currentUserOrNull()?.id
    }
}