package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.background
import com.iraqsouq.app.ui.Format
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun ChatsScreen(
    vm: MainViewModel,
    onRequireLogin: () -> Unit,
    onOpenChat: (conversationId: String, listingId: Long, otherUserId: Long) -> Unit,
) {
    val currentUser by vm.currentUser.collectAsState()
    val inbox by vm.inbox.collectAsState()

    val user = currentUser
    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = "المحادثات")

        if (user == null) {
            Column(
                Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(Icons.Filled.Login, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(56.dp))
                Spacer(Modifier.size(12.dp))
                Text("سجّل الدخول لعرض محادثاتك", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.size(16.dp))
                Button(onClick = onRequireLogin) { Text("تسجيل الدخول") }
            }
        } else if (inbox.isEmpty()) {
            EmptyState("لا توجد محادثات بعد")
        } else {
            val myId = user.id
            LazyColumn(Modifier.fillMaxSize()) {
                items(inbox, key = { it.conversationId }) { message ->
                val otherId = if (message.senderId == myId) message.receiverId else message.senderId
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { onOpenChat(message.conversationId, message.listingId, otherId) }
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier.size(46.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Person, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    }
                    Spacer(Modifier.size(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(message.listingTitle, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(
                            (if (message.senderId == myId) "أنت: " else "") + message.text,
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.Gray,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Spacer(Modifier.size(8.dp))
                    Text(Format.timeAgo(message.createdAt), style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                }
                    HorizontalDivider()
                }
            }
        }
    }
}
