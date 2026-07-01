package com.iraqsouq.app.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(tableName = "users", indices = [Index(value = ["phone"], unique = true)])
data class User(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val phone: String,
    val password: String,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "listings")
data class Listing(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val description: String,
    val price: Long,
    val negotiable: Boolean = false,
    val categoryId: String,
    val governorate: String,
    /** Comma-separated list of image URIs (content:// or asset placeholders). */
    val images: List<String> = emptyList(),
    val sellerId: Long,
    val sellerName: String,
    val sellerPhone: String,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "favorites",
    primaryKeys = ["userId", "listingId"],
)
data class Favorite(
    val userId: Long,
    val listingId: Long,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "messages")
data class Message(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    /** Stable conversation key so both participants share the same thread. */
    val conversationId: String,
    val listingId: Long,
    val listingTitle: String,
    val senderId: Long,
    val receiverId: Long,
    val text: String,
    val createdAt: Long = System.currentTimeMillis(),
)
