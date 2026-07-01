package com.iraqsouq.app.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chair
import androidx.compose.material.icons.filled.Checkroom
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Devices
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.Pets
import androidx.compose.material.icons.filled.Work
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material.icons.filled.Smartphone
import androidx.compose.ui.graphics.vector.ImageVector

/** A marketplace category, similar to Kleinanzeigen's rubrics. */
data class Category(
    val id: String,
    val nameAr: String,
    val icon: ImageVector,
)

object Categories {
    val all: List<Category> = listOf(
        Category("cars", "سيارات ومركبات", Icons.Filled.DirectionsCar),
        Category("phones", "هواتف وأجهزة", Icons.Filled.Smartphone),
        Category("electronics", "إلكترونيات", Icons.Filled.Devices),
        Category("realestate", "عقارات", Icons.Filled.Apartment),
        Category("furniture", "أثاث ومنزل", Icons.Filled.Chair),
        Category("fashion", "أزياء وملابس", Icons.Filled.Checkroom),
        Category("jobs", "وظائف", Icons.Filled.Work),
        Category("pets", "حيوانات أليفة", Icons.Filled.Pets),
        Category("kids", "مستلزمات الأطفال", Icons.Filled.SmartToy),
        Category("other", "أخرى", Icons.Filled.Widgets),
    )

    fun nameOf(id: String): String = all.firstOrNull { it.id == id }?.nameAr ?: "أخرى"
    fun iconOf(id: String): ImageVector = all.firstOrNull { it.id == id }?.icon ?: Icons.Filled.Widgets
}

/** The 18 Iraqi governorates. */
object Governorates {
    val all: List<String> = listOf(
        "بغداد",
        "البصرة",
        "نينوى",
        "أربيل",
        "النجف",
        "كربلاء",
        "كركوك",
        "السليمانية",
        "ذي قار",
        "الأنبار",
        "بابل",
        "ديالى",
        "واسط",
        "صلاح الدين",
        "المثنى",
        "القادسية",
        "ميسان",
        "دهوك",
    )
}
