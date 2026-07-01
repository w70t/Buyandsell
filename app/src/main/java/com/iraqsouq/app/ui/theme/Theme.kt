package com.iraqsouq.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val GreenPrimary = Color(0xFF0F7A3D)
val GreenDark = Color(0xFF0A5A2C)
val Amber = Color(0xFFF5A623)
val SurfaceLight = Color(0xFFF6F7F9)

private val LightColors = lightColorScheme(
    primary = GreenPrimary,
    onPrimary = Color.White,
    secondary = Amber,
    onSecondary = Color.White,
    background = SurfaceLight,
    surface = Color.White,
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF4CC57D),
    onPrimary = Color.Black,
    secondary = Amber,
)

@Composable
fun IraqSouqTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = Typography(),
        content = content,
    )
}
