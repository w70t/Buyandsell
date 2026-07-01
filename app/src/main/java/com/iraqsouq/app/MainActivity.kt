package com.iraqsouq.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.lifecycle.viewmodel.compose.viewModel
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.nav.AppRoot
import com.iraqsouq.app.ui.theme.IraqSouqTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val repository = (application as MarketApp).repository
        setContent {
            // Force right-to-left layout for the Arabic interface.
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                IraqSouqTheme {
                    val vm: MainViewModel = viewModel(factory = MainViewModel.factory(repository))
                    AppRoot(vm)
                }
            }
        }
    }
}
