package com.iraqsouq.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.iraqsouq.app.data.Listing
import com.iraqsouq.app.data.Message
import com.iraqsouq.app.data.Repository
import com.iraqsouq.app.data.SessionUser
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch

@OptIn(ExperimentalCoroutinesApi::class)
class MainViewModel(private val repo: Repository) : ViewModel() {

    // ---- Session ----
    val currentUser: StateFlow<SessionUser?> =
        repo.session.currentUser.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    private val _authError = MutableStateFlow<String?>(null)
    val authError: StateFlow<String?> = _authError.asStateFlow()

    init {
        viewModelScope.launch { repo.seedIfEmpty() }
    }

    fun clearAuthError() { _authError.value = null }

    fun login(phone: String, password: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            when (val r = repo.login(phone, password)) {
                is Repository.AuthResult.Success -> { _authError.value = null; onSuccess() }
                is Repository.AuthResult.Error -> _authError.value = r.message
            }
        }
    }

    fun register(name: String, phone: String, password: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            when (val r = repo.register(name, phone, password)) {
                is Repository.AuthResult.Success -> { _authError.value = null; onSuccess() }
                is Repository.AuthResult.Error -> _authError.value = r.message
            }
        }
    }

    fun logout() { viewModelScope.launch { repo.logout() } }

    // ---- Listings ----
    val allListings: StateFlow<List<Listing>> =
        repo.listings().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun listingsByCategory(categoryId: String): Flow<List<Listing>> =
        repo.listingsByCategory(categoryId)

    val myListings: StateFlow<List<Listing>> =
        currentUser.flatMapLatest { user ->
            if (user == null) emptyFlow() else repo.listingsBySeller(user.id)
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    suspend fun getListing(id: Long): Listing? = repo.listing(id)

    fun publishListing(
        title: String,
        description: String,
        price: Long,
        negotiable: Boolean,
        categoryId: String,
        governorate: String,
        images: List<String>,
        onDone: (Long) -> Unit,
    ) {
        val user = currentUser.value ?: return
        viewModelScope.launch {
            val id = repo.addListing(
                Listing(
                    title = title.trim(),
                    description = description.trim(),
                    price = price,
                    negotiable = negotiable,
                    categoryId = categoryId,
                    governorate = governorate,
                    images = images,
                    sellerId = user.id,
                    sellerName = user.name,
                    sellerPhone = user.phone,
                )
            )
            onDone(id)
        }
    }

    fun deleteListing(id: Long) {
        val user = currentUser.value ?: return
        viewModelScope.launch { repo.deleteListing(id, user.id) }
    }

    // ---- Favorites ----
    val favoriteIds: StateFlow<Set<Long>> =
        currentUser.flatMapLatest { user ->
            if (user == null) emptyFlow() else repo.favoriteIds(user.id)
        }.map { it.toSet() }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    val favoriteListings: StateFlow<List<Listing>> =
        currentUser.flatMapLatest { user ->
            if (user == null) emptyFlow() else repo.favoriteListings(user.id)
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun toggleFavorite(listingId: Long) {
        val user = currentUser.value ?: return
        val isFav = favoriteIds.value.contains(listingId)
        viewModelScope.launch { repo.toggleFavorite(user.id, listingId, !isFav) }
    }

    // ---- Messaging ----
    val inbox: StateFlow<List<Message>> =
        currentUser.flatMapLatest { user ->
            if (user == null) emptyFlow() else repo.inbox(user.id)
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun conversation(conversationId: String): Flow<List<Message>> =
        repo.conversation(conversationId)

    fun conversationId(listingId: Long, otherUserId: Long): String? {
        val user = currentUser.value ?: return null
        return repo.conversationId(listingId, user.id, otherUserId)
    }

    fun sendMessage(listingId: Long, listingTitle: String, receiverId: Long, text: String) {
        val user = currentUser.value ?: return
        if (text.isBlank()) return
        viewModelScope.launch {
            repo.sendMessage(listingId, listingTitle, user.id, receiverId, text)
        }
    }

    companion object {
        fun factory(repo: Repository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    MainViewModel(repo) as T
            }
    }
}
