package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.model.Categories
import com.iraqsouq.app.model.Governorates
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.ListingCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    vm: MainViewModel,
    onListingClick: (Long) -> Unit,
) {
    val listings by vm.allListings.collectAsState()
    val favorites by vm.favoriteIds.collectAsState()

    var query by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf<String?>(null) }
    var selectedGov by remember { mutableStateOf<String?>(null) }

    val results = remember(listings, query, selectedCategory, selectedGov) {
        listings.filter { l ->
            (query.isBlank() ||
                l.title.contains(query, ignoreCase = true) ||
                l.description.contains(query, ignoreCase = true)) &&
                (selectedCategory == null || l.categoryId == selectedCategory) &&
                (selectedGov == null || l.governorate == selectedGov)
        }
    }

    Column(Modifier.fillMaxSize().padding(12.dp)) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            placeholder = { Text("ابحث عن سيارات، هواتف، عقارات…") },
            leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
            trailingIcon = {
                if (query.isNotEmpty()) {
                    IconButton(onClick = { query = "" }) {
                        Icon(Icons.Filled.Close, contentDescription = "مسح")
                    }
                }
            },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(8.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            item {
                FilterChip(
                    selected = selectedCategory == null,
                    onClick = { selectedCategory = null },
                    label = { Text("كل الأقسام") },
                )
            }
            items(Categories.all) { cat ->
                FilterChip(
                    selected = selectedCategory == cat.id,
                    onClick = { selectedCategory = if (selectedCategory == cat.id) null else cat.id },
                    label = { Text(cat.nameAr) },
                )
            }
        }
        Spacer(Modifier.height(6.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            item {
                FilterChip(
                    selected = selectedGov == null,
                    onClick = { selectedGov = null },
                    label = { Text("كل المحافظات") },
                )
            }
            items(Governorates.all) { gov ->
                FilterChip(
                    selected = selectedGov == gov,
                    onClick = { selectedGov = if (selectedGov == gov) null else gov },
                    label = { Text(gov) },
                )
            }
        }
        Spacer(Modifier.height(8.dp))
        Text("${results.size} نتيجة", style = androidx.compose.material3.MaterialTheme.typography.labelLarge)
        Spacer(Modifier.height(8.dp))

        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(bottom = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxSize(),
        ) {
            items(results, key = { it.id }) { listing ->
                ListingCard(
                    listing = listing,
                    isFavorite = favorites.contains(listing.id),
                    onClick = { onListingClick(listing.id) },
                    onToggleFavorite = { vm.toggleFavorite(listing.id) },
                )
            }
            if (results.isEmpty()) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    EmptyState("لا توجد نتائج")
                }
            }
        }
    }
}
