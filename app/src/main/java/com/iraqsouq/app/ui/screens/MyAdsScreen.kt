package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.data.Listing
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.ListingCard
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun MyAdsScreen(
    vm: MainViewModel,
    onBack: () -> Unit,
    onListingClick: (Long) -> Unit,
) {
    val listings by vm.myListings.collectAsState()
    val favorites by vm.favoriteIds.collectAsState()
    var toDelete by remember { mutableStateOf<Listing?>(null) }

    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = "إعلاناتي", onBack = onBack)
        if (listings.isEmpty()) {
            EmptyState("لم تنشر أي إعلان بعد")
        } else {
            LazyColumn(
                contentPadding = PaddingValues(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(listings, key = { it.id }) { listing ->
                    Box {
                        ListingCard(
                            listing = listing,
                            isFavorite = favorites.contains(listing.id),
                            onClick = { onListingClick(listing.id) },
                            onToggleFavorite = { vm.toggleFavorite(listing.id) },
                        )
                        IconButton(
                            onClick = { toDelete = listing },
                            modifier = Modifier.align(Alignment.TopStart),
                        ) {
                            Icon(Icons.Filled.Delete, contentDescription = "حذف", tint = androidx.compose.ui.graphics.Color.Red)
                        }
                    }
                }
            }
        }
    }

    toDelete?.let { listing ->
        AlertDialog(
            onDismissRequest = { toDelete = null },
            title = { Text("حذف الإعلان") },
            text = { Text("هل تريد حذف \"${listing.title}\"؟") },
            confirmButton = {
                TextButton(onClick = { vm.deleteListing(listing.id); toDelete = null }) {
                    Text("حذف")
                }
            },
            dismissButton = {
                TextButton(onClick = { toDelete = null }) { Text("إلغاء") }
            },
        )
    }
}
