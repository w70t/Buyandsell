package com.iraqsouq.app.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(user: User): Long

    @Query("SELECT * FROM users WHERE phone = :phone LIMIT 1")
    suspend fun findByPhone(phone: String): User?

    @Query("SELECT * FROM users WHERE id = :id LIMIT 1")
    suspend fun findById(id: Long): User?

    @Query("SELECT COUNT(*) FROM users")
    suspend fun count(): Int
}

@Dao
interface ListingDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(listing: Listing): Long

    @Query("DELETE FROM listings WHERE id = :id AND sellerId = :sellerId")
    suspend fun delete(id: Long, sellerId: Long)

    @Query("SELECT * FROM listings ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<Listing>>

    @Query("SELECT * FROM listings WHERE categoryId = :categoryId ORDER BY createdAt DESC")
    fun observeByCategory(categoryId: String): Flow<List<Listing>>

    @Query("SELECT * FROM listings WHERE sellerId = :sellerId ORDER BY createdAt DESC")
    fun observeBySeller(sellerId: Long): Flow<List<Listing>>

    @Query("SELECT * FROM listings WHERE id = :id LIMIT 1")
    suspend fun findById(id: Long): Listing?

    @Query("SELECT COUNT(*) FROM listings")
    suspend fun count(): Int
}

@Dao
interface FavoriteDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun add(favorite: Favorite)

    @Query("DELETE FROM favorites WHERE userId = :userId AND listingId = :listingId")
    suspend fun remove(userId: Long, listingId: Long)

    @Query("SELECT listingId FROM favorites WHERE userId = :userId")
    fun observeFavoriteIds(userId: Long): Flow<List<Long>>

    @Query(
        "SELECT l.* FROM listings l INNER JOIN favorites f ON l.id = f.listingId " +
            "WHERE f.userId = :userId ORDER BY f.createdAt DESC"
    )
    fun observeFavoriteListings(userId: Long): Flow<List<Listing>>
}

@Dao
interface MessageDao {
    @Insert
    suspend fun insert(message: Message): Long

    @Query("SELECT * FROM messages WHERE conversationId = :conversationId ORDER BY createdAt ASC")
    fun observeConversation(conversationId: String): Flow<List<Message>>

    /** Latest message per conversation the user participates in. */
    @Query(
        "SELECT * FROM messages WHERE id IN (" +
            "SELECT MAX(id) FROM messages " +
            "WHERE senderId = :userId OR receiverId = :userId " +
            "GROUP BY conversationId) ORDER BY createdAt DESC"
    )
    fun observeInbox(userId: Long): Flow<List<Message>>
}
