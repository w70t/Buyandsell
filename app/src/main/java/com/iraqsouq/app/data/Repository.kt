package com.iraqsouq.app.data

import kotlinx.coroutines.flow.Flow

/** Single entry point for all data operations used by the ViewModels. */
class Repository(
    private val userDao: UserDao,
    private val listingDao: ListingDao,
    private val favoriteDao: FavoriteDao,
    private val messageDao: MessageDao,
    val session: SessionManager,
) {
    // ---- Auth ----
    sealed interface AuthResult {
        data class Success(val user: User) : AuthResult
        data class Error(val message: String) : AuthResult
    }

    suspend fun register(name: String, phone: String, password: String): AuthResult {
        if (name.isBlank() || phone.isBlank() || password.length < 4) {
            return AuthResult.Error("يرجى تعبئة الحقول (كلمة المرور 4 أحرف على الأقل)")
        }
        if (userDao.findByPhone(phone) != null) {
            return AuthResult.Error("رقم الهاتف مسجّل مسبقاً")
        }
        val id = userDao.insert(User(name = name.trim(), phone = phone.trim(), password = password))
        val user = userDao.findById(id)!!
        session.save(user)
        return AuthResult.Success(user)
    }

    suspend fun login(phone: String, password: String): AuthResult {
        val user = userDao.findByPhone(phone.trim())
            ?: return AuthResult.Error("لا يوجد حساب بهذا الرقم")
        if (user.password != password) {
            return AuthResult.Error("كلمة المرور غير صحيحة")
        }
        session.save(user)
        return AuthResult.Success(user)
    }

    suspend fun logout() = session.clear()

    // ---- Listings ----
    fun listings(): Flow<List<Listing>> = listingDao.observeAll()
    fun listingsByCategory(categoryId: String): Flow<List<Listing>> =
        listingDao.observeByCategory(categoryId)
    fun listingsBySeller(sellerId: Long): Flow<List<Listing>> =
        listingDao.observeBySeller(sellerId)
    suspend fun listing(id: Long): Listing? = listingDao.findById(id)
    suspend fun addListing(listing: Listing): Long = listingDao.insert(listing)
    suspend fun deleteListing(id: Long, sellerId: Long) = listingDao.delete(id, sellerId)

    // ---- Favorites ----
    fun favoriteIds(userId: Long): Flow<List<Long>> = favoriteDao.observeFavoriteIds(userId)
    fun favoriteListings(userId: Long): Flow<List<Listing>> =
        favoriteDao.observeFavoriteListings(userId)

    suspend fun toggleFavorite(userId: Long, listingId: Long, isFavorite: Boolean) {
        if (isFavorite) favoriteDao.add(Favorite(userId, listingId))
        else favoriteDao.remove(userId, listingId)
    }

    // ---- Messaging ----
    fun conversation(conversationId: String): Flow<List<Message>> =
        messageDao.observeConversation(conversationId)
    fun inbox(userId: Long): Flow<List<Message>> = messageDao.observeInbox(userId)

    suspend fun sendMessage(
        listingId: Long,
        listingTitle: String,
        senderId: Long,
        receiverId: Long,
        text: String,
    ) {
        val conversationId = conversationId(listingId, senderId, receiverId)
        messageDao.insert(
            Message(
                conversationId = conversationId,
                listingId = listingId,
                listingTitle = listingTitle,
                senderId = senderId,
                receiverId = receiverId,
                text = text.trim(),
            )
        )
    }

    /** Deterministic key so both participants land on the same thread for a listing. */
    fun conversationId(listingId: Long, a: Long, b: Long): String {
        val (low, high) = if (a <= b) a to b else b to a
        return "c.$listingId.$low.$high"
    }

    // ---- Seeding ----
    suspend fun seedIfEmpty() {
        if (listingDao.count() > 0) return
        SeedData.demoListings.forEach { listingDao.insert(it) }
    }
}
