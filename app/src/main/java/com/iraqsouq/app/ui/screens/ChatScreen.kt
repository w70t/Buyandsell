package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun ChatScreen(
    vm: MainViewModel,
    conversationId: String,
    listingId: Long,
    otherUserId: Long,
    onBack: () -> Unit,
) {
    val currentUser by vm.currentUser.collectAsState()
    val messagesFlow = remember(conversationId) { vm.conversation(conversationId) }
    val messages by messagesFlow.collectAsState(initial = emptyList())
    var input by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    val myId = currentUser?.id ?: -999L
    val listingFromDb by produceState(initialValue = null as String?, listingId) {
        value = vm.getListing(listingId)?.title
    }
    val listingTitle = messages.firstOrNull()?.listingTitle ?: listingFromDb ?: "محادثة"

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.size - 1)
    }

    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = listingTitle, onBack = onBack)

        if (messages.isEmpty()) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text("ابدأ المحادثة الآن", color = Color.Gray)
            }
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).fillMaxWidth(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(messages, key = { it.id }) { msg ->
                    val mine = msg.senderId == myId
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = if (mine) Arrangement.Start else Arrangement.End,
                    ) {
                        Surface(
                            color = if (mine) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                            shape = RoundedCornerShape(14.dp),
                            modifier = Modifier.widthIn(max = 280.dp),
                        ) {
                            Text(
                                msg.text,
                                color = if (mine) Color.White else MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            )
                        }
                    }
                }
            }
        }

        Surface(shadowElevation = 8.dp) {
            Row(
                Modifier.fillMaxWidth().padding(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    placeholder = { Text("اكتب رسالة…") },
                    modifier = Modifier.weight(1f),
                    maxLines = 4,
                )
                Spacer(Modifier.padding(4.dp))
                IconButton(
                    onClick = {
                        vm.sendMessage(listingId, listingTitle, otherUserId, input)
                        input = ""
                    },
                    enabled = input.isNotBlank(),
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "إرسال",
                        tint = if (input.isNotBlank()) MaterialTheme.colorScheme.primary else Color.Gray,
                    )
                }
            }
        }
    }
}
