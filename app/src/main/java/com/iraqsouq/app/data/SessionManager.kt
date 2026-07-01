package com.iraqsouq.app.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "session")

/** Persists the logged-in user across app launches. */
class SessionManager(private val context: Context) {
    private val keyUserId = longPreferencesKey("user_id")
    private val keyUserName = stringPreferencesKey("user_name")
    private val keyUserPhone = stringPreferencesKey("user_phone")

    val currentUser: Flow<SessionUser?> = context.dataStore.data.map { prefs ->
        val id = prefs[keyUserId] ?: return@map null
        SessionUser(
            id = id,
            name = prefs[keyUserName] ?: "",
            phone = prefs[keyUserPhone] ?: "",
        )
    }

    suspend fun save(user: User) {
        context.dataStore.edit { prefs ->
            prefs[keyUserId] = user.id
            prefs[keyUserName] = user.name
            prefs[keyUserPhone] = user.phone
        }
    }

    suspend fun clear() {
        context.dataStore.edit { it.clear() }
    }
}

data class SessionUser(
    val id: Long,
    val name: String,
    val phone: String,
)
