package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.ListingCard
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun FavoritesScreen(
    vm: MainViewModel,
    onBack: () -> Unit,
    onListingClick: (Long) -> Unit,
) {
    val listings by vm.favoriteListings.collectAsState()
    val favorites by vm.favoriteIds.collectAsState()

    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = "المفضلة", onBack = onBack)
        if (listings.isEmpty()) {
            EmptyState("لا توجد إعلانات في المفضلة")
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                items(listings, key = { it.id }) { listing ->
                    ListingCard(
                        listing = listing,
                        isFavorite = favorites.contains(listing.id),
                        onClick = { onListingClick(listing.id) },
                        onToggleFavorite = { vm.toggleFavorite(listing.id) },
                    )
                }
            }
        }
    }
}
