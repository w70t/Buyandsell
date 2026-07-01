package com.iraqsouq.app.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.SimpleTopBar

@Composable
fun ProfileScreen(
    vm: MainViewModel,
    onRequireLogin: () -> Unit,
    onMyAds: () -> Unit,
    onFavorites: () -> Unit,
) {
    val user by vm.currentUser.collectAsState()

    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = "حسابي")

        val current = user
        if (current == null) {
            Column(
                Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(Icons.Filled.Login, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(56.dp))
                Spacer(Modifier.size(12.dp))
                Text("لم تسجّل الدخول بعد", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.size(16.dp))
                Button(onClick = onRequireLogin) { Text("تسجيل الدخول / إنشاء حساب") }
            }
        } else {
            Column(Modifier.fillMaxSize()) {
                Row(
                    Modifier.fillMaxWidth().padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier.size(64.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Person, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(36.dp))
                    }
                    Spacer(Modifier.size(16.dp))
                    Column {
                        Text(current.name, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(current.phone, color = Color.Gray)
                    }
                }
                HorizontalDivider()

                ProfileRow(Icons.Filled.Inventory2, "إعلاناتي", onMyAds)
                HorizontalDivider()
                ProfileRow(Icons.Filled.Favorite, "المفضلة", onFavorites)
                HorizontalDivider()
                ProfileRow(Icons.AutoMirrored.Filled.Logout, "تسجيل الخروج", { vm.logout() })
            }
        }
    }
}

@Composable
private fun ProfileRow(icon: ImageVector, label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(18.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.size(16.dp))
        Text(label, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        Icon(Icons.Filled.ChevronLeft, contentDescription = null, tint = Color.Gray)
    }
}
