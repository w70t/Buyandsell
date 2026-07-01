package com.iraqsouq.app

import android.app.Application
import com.iraqsouq.app.data.AppDatabase
import com.iraqsouq.app.data.Repository
import com.iraqsouq.app.data.SessionManager

/** Minimal manual dependency container shared across the app. */
class MarketApp : Application() {
    lateinit var repository: Repository
        private set

    override fun onCreate() {
        super.onCreate()
        val db = AppDatabase.get(this)
        repository = Repository(
            userDao = db.userDao(),
            listingDao = db.listingDao(),
            favoriteDao = db.favoriteDao(),
            messageDao = db.messageDao(),
            session = SessionManager(this),
        )
    }
}
