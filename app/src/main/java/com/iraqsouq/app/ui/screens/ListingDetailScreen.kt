package com.iraqsouq.app.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.ImageNotSupported
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.iraqsouq.app.data.Listing
import com.iraqsouq.app.model.Categories
import com.iraqsouq.app.ui.Format
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun ListingDetailScreen(
    vm: MainViewModel,
    listingId: Long,
    onBack: () -> Unit,
    onRequireLogin: () -> Unit,
    onOpenChat: (conversationId: String, listingId: Long, otherUserId: Long) -> Unit,
) {
    val context = LocalContext.current
    val listingState by produceState<Listing?>(initialValue = null, listingId) {
        value = vm.getListing(listingId)
    }
    val favorites by vm.favoriteIds.collectAsState()
    val currentUser by vm.currentUser.collectAsState()

    val listing = listingState
    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(
            title = "تفاصيل الإعلان",
            onBack = onBack,
            actions = {
                if (listing != null) {
                    val isFav = favorites.contains(listing.id)
                    androidx.compose.material3.IconButton(onClick = { vm.toggleFavorite(listing.id) }) {
                        Icon(
                            if (isFav) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                            contentDescription = "المفضلة",
                            tint = Color.White,
                        )
                    }
                }
            },
        )

        if (listing == null) {
            EmptyState("الإعلان غير موجود")
            return@Column
        }

        Column(
            Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        ) {
            // Image gallery
            if (listing.images.isNotEmpty()) {
                val pagerState = rememberPagerState(pageCount = { listing.images.size })
                Box {
                    HorizontalPager(state = pagerState, modifier = Modifier.fillMaxWidth()) { page ->
                        AsyncImage(
                            model = listing.images[page],
                            contentDescription = listing.title,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .fillMaxWidth()
                                .aspectRatio(4f / 3f),
                        )
                    }
                    if (listing.images.size > 1) {
                        Surface(
                            color = Color.Black.copy(alpha = 0.5f),
                            shape = RoundedCornerShape(50),
                            modifier = Modifier.align(Alignment.BottomCenter).padding(8.dp),
                        ) {
                            Text(
                                "${pagerState.currentPage + 1} / ${listing.images.size}",
                                color = Color.White,
                                style = MaterialTheme.typography.labelSmall,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            )
                        }
                    }
                }
            } else {
                Box(
                    Modifier.fillMaxWidth().aspectRatio(4f / 3f).background(Color(0xFFEEEEEE)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.ImageNotSupported, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(48.dp))
                }
            }

            Column(Modifier.padding(16.dp)) {
                Text(listing.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                Text(
                    Format.price(listing.price),
                    style = MaterialTheme.typography.headlineSmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold,
                )
                if (listing.negotiable) {
                    Text("قابل للتفاوض", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.secondary)
                }
                Spacer(Modifier.height(10.dp))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(Icons.Filled.LocationOn, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(16.dp))
                    Text(listing.governorate, color = Color.Gray, style = MaterialTheme.typography.bodyMedium)
                    Text(" • " + Categories.nameOf(listing.categoryId), color = Color.Gray, style = MaterialTheme.typography.bodyMedium)
                    Text(" • " + Format.timeAgo(listing.createdAt), color = Color.Gray, style = MaterialTheme.typography.bodySmall)
                }

                Spacer(Modifier.height(16.dp))
                Text("الوصف", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(4.dp))
                Text(listing.description, style = MaterialTheme.typography.bodyLarge)

                Spacer(Modifier.height(16.dp))
                Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
                    Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.size(44.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Person, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        }
                        Spacer(Modifier.size(12.dp))
                        Column {
                            Text(listing.sellerName, fontWeight = FontWeight.SemiBold)
                            Text(listing.sellerPhone, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                        }
                    }
                }
                Spacer(Modifier.height(80.dp))
            }
        }

        // Bottom action bar
        Surface(shadowElevation = 8.dp) {
            Row(
                Modifier.fillMaxWidth().padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedButton(
                    onClick = {
                        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:${listing.sellerPhone}"))
                        context.startActivity(intent)
                    },
                    modifier = Modifier.weight(1f).height(50.dp),
                ) {
                    Icon(Icons.Filled.Call, contentDescription = null)
                    Spacer(Modifier.size(6.dp))
                    Text("اتصال")
                }
                Button(
                    onClick = {
                        val me = currentUser
                        if (me == null) {
                            onRequireLogin()
                        } else if (me.id == listing.sellerId) {
                            // Can't chat with yourself
                        } else {
                            val convId = vm.conversationId(listing.id, listing.sellerId)
                            if (convId != null) onOpenChat(convId, listing.id, listing.sellerId)
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                    modifier = Modifier.weight(1f).height(50.dp),
                ) {
                    Icon(Icons.Filled.ChatBubble, contentDescription = null)
                    Spacer(Modifier.size(6.dp))
                    Text("مراسلة البائع")
                }
            }
        }
    }
}
