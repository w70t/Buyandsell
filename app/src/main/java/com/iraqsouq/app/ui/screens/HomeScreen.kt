package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.model.Categories
import com.iraqsouq.app.model.Category
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.ListingCard

@Composable
fun HomeScreen(
    vm: MainViewModel,
    onListingClick: (Long) -> Unit,
    onCategoryClick: (String) -> Unit,
) {
    val listings by vm.allListings.collectAsState()
    val favorites by vm.favoriteIds.collectAsState()

    Column(Modifier.fillMaxSize()) {
        HomeHeader()
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxSize(),
        ) {
            item(span = { GridItemSpan(maxLineSpan) }) {
                Column {
                    SectionTitle("الأقسام")
                    Spacer(Modifier.height(8.dp))
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        items(Categories.all) { category ->
                            CategoryChip(category) { onCategoryClick(category.id) }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    SectionTitle("أحدث الإعلانات")
                }
            }
            items(listings, key = { it.id }) { listing ->
                ListingCard(
                    listing = listing,
                    isFavorite = favorites.contains(listing.id),
                    onClick = { onListingClick(listing.id) },
                    onToggleFavorite = { vm.toggleFavorite(listing.id) },
                )
            }
            if (listings.isEmpty()) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    EmptyState("لا توجد إعلانات بعد")
                }
            }
        }
    }
}

@Composable
private fun HomeHeader() {
    Surface(color = MaterialTheme.colorScheme.primary) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Text(
                "سوق العراق",
                color = Color.White,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.height(10.dp))
            Surface(
                color = Color.White,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Row(
                    Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.Search, contentDescription = null, tint = Color.Gray)
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "ابحث عن سيارات، هواتف، عقارات…",
                        color = Color.Gray,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
    }
}

@Composable
fun SectionTitle(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
    )
}

@Composable
private fun CategoryChip(category: Category, onClick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(76.dp).clickable(onClick = onClick),
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                category.icon,
                contentDescription = category.nameAr,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(28.dp),
            )
        }
        Spacer(Modifier.height(6.dp))
        Text(
            category.nameAr,
            style = MaterialTheme.typography.labelSmall,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
fun EmptyState(message: String) {
    Box(
        Modifier.fillMaxWidth().padding(40.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(message, color = Color.Gray, style = MaterialTheme.typography.bodyLarge)
    }
}
