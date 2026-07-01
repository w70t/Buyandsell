package com.iraqsouq.app.ui.screens

import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Login
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.iraqsouq.app.model.Categories
import com.iraqsouq.app.model.Governorates
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.components.SimpleTopBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PostAdScreen(
    vm: MainViewModel,
    onRequireLogin: () -> Unit,
    onPublished: (Long) -> Unit,
) {
    val currentUser by vm.currentUser.collectAsState()
    val context = LocalContext.current

    if (currentUser == null) {
        Column(Modifier.fillMaxSize()) {
            SimpleTopBar(title = "أضف إعلان")
            Column(
                Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Icon(Icons.Filled.Login, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(56.dp))
                Spacer(Modifier.height(12.dp))
                Text("سجّل الدخول لنشر إعلان", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.height(16.dp))
                Button(onClick = onRequireLogin) { Text("تسجيل الدخول / إنشاء حساب") }
            }
        }
        return
    }

    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var negotiable by remember { mutableStateOf(false) }
    var category by remember { mutableStateOf(Categories.all.first().id) }
    var governorate by remember { mutableStateOf(Governorates.all.first()) }
    var images by remember { mutableStateOf<List<String>>(emptyList()) }
    var showError by remember { mutableStateOf(false) }

    val pickImages = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenMultipleDocuments,
    ) { uris ->
        val newOnes = uris.mapNotNull { uri ->
            try {
                context.contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
                uri.toString()
            } catch (e: SecurityException) {
                uri.toString()
            }
        }
        images = (images + newOnes).distinct()
    }

    val priceValue = price.filter { it.isDigit() }.toLongOrNull() ?: 0L
    val isValid = title.isNotBlank() && description.isNotBlank() && priceValue > 0

    Column(Modifier.fillMaxSize()) {
        SimpleTopBar(title = "أضف إعلان")
        Column(
            Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            Text("الصور", fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                item {
                    Box(
                        Modifier
                            .size(90.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                            .clickable { pickImages.launch(arrayOf("image/*")) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Filled.AddAPhoto, contentDescription = "إضافة صور", tint = MaterialTheme.colorScheme.primary)
                            Text("إضافة", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
                items(images) { uri ->
                    Box(Modifier.size(90.dp)) {
                        AsyncImage(
                            model = uri,
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.size(90.dp).clip(RoundedCornerShape(10.dp)),
                        )
                        Box(
                            Modifier
                                .align(Alignment.TopEnd)
                                .padding(2.dp)
                                .size(22.dp)
                                .clip(RoundedCornerShape(50))
                                .background(Color.Black.copy(alpha = 0.6f))
                                .clickable { images = images - uri },
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Close, contentDescription = "حذف", tint = Color.White, modifier = Modifier.size(14.dp))
                        }
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("العنوان") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("الوصف") },
                minLines = 3,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = price,
                onValueChange = { price = it.filter { c -> c.isDigit() } },
                label = { Text("السعر (د.ع)") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Switch(checked = negotiable, onCheckedChange = { negotiable = it })
                Spacer(Modifier.size(8.dp))
                Text("قابل للتفاوض")
            }

            Spacer(Modifier.height(12.dp))
            DropdownField(
                label = "القسم",
                value = Categories.nameOf(category),
                options = Categories.all.map { it.id to it.nameAr },
                onSelected = { category = it },
            )
            Spacer(Modifier.height(12.dp))
            DropdownField(
                label = "المحافظة",
                value = governorate,
                options = Governorates.all.map { it to it },
                onSelected = { governorate = it },
            )

            if (showError && !isValid) {
                Spacer(Modifier.height(8.dp))
                Text("يرجى تعبئة العنوان والوصف والسعر", color = MaterialTheme.colorScheme.error)
            }
            Spacer(Modifier.height(16.dp))
        }

        Button(
            onClick = {
                if (!isValid) {
                    showError = true
                } else {
                    vm.publishListing(
                        title = title,
                        description = description,
                        price = priceValue,
                        negotiable = negotiable,
                        categoryId = category,
                        governorate = governorate,
                        images = images,
                        onDone = onPublished,
                    )
                }
            },
            modifier = Modifier.fillMaxWidth().padding(16.dp).height(52.dp),
        ) {
            Text("نشر الإعلان", style = MaterialTheme.typography.titleMedium)
        }
    }
}

@Composable
private fun DropdownField(
    label: String,
    value: String,
    options: List<Pair<String, String>>,
    onSelected: (String) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = value,
            onValueChange = {},
            readOnly = true,
            enabled = false,
            label = { Text(label) },
            trailingIcon = { Icon(Icons.Filled.ArrowDropDown, contentDescription = null) },
            colors = OutlinedTextFieldDefaults.colors(
                disabledTextColor = MaterialTheme.colorScheme.onSurface,
                disabledBorderColor = MaterialTheme.colorScheme.outline,
                disabledLabelColor = MaterialTheme.colorScheme.onSurfaceVariant,
                disabledTrailingIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
        // Transparent overlay captures the tap to open the menu.
        Box(
            Modifier
                .matchParentSize()
                .clickable { expanded = true },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.forEach { (key, display) ->
                DropdownMenuItem(
                    text = { Text(display) },
                    onClick = { onSelected(key); expanded = false },
                )
            }
        }
    }
}
