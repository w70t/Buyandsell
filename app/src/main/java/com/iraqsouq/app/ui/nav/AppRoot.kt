package com.iraqsouq.app.ui.nav

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.iraqsouq.app.ui.MainViewModel
import com.iraqsouq.app.ui.screens.AuthScreen
import com.iraqsouq.app.ui.screens.CategoryScreen
import com.iraqsouq.app.ui.screens.ChatScreen
import com.iraqsouq.app.ui.screens.ChatsScreen
import com.iraqsouq.app.ui.screens.FavoritesScreen
import com.iraqsouq.app.ui.screens.HomeScreen
import com.iraqsouq.app.ui.screens.ListingDetailScreen
import com.iraqsouq.app.ui.screens.MyAdsScreen
import com.iraqsouq.app.ui.screens.PostAdScreen
import com.iraqsouq.app.ui.screens.ProfileScreen
import com.iraqsouq.app.ui.screens.SearchScreen

private data class TabSpec(
    val tab: BottomTab,
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
)

private val tabs = listOf(
    TabSpec(BottomTab.Home, "الرئيسية", Icons.Filled.Home),
    TabSpec(BottomTab.Search, "بحث", Icons.Filled.Search),
    TabSpec(BottomTab.PostAd, "أضف إعلان", Icons.Filled.AddCircle),
    TabSpec(BottomTab.Chats, "المحادثات", Icons.Filled.ChatBubble),
    TabSpec(BottomTab.Profile, "حسابي", Icons.Filled.Person),
)

@Composable
fun AppRoot(vm: MainViewModel) {
    val navController = rememberNavController()
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route

    val showBottomBar = currentRoute in tabs.map { it.tab.route }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    tabs.forEach { spec ->
                        NavigationBarItem(
                            selected = currentRoute == spec.tab.route,
                            onClick = {
                                if (currentRoute != spec.tab.route) {
                                    navController.navigate(spec.tab.route) {
                                        popUpTo(Routes.HOME) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                            },
                            icon = { Icon(spec.icon, contentDescription = spec.label) },
                            label = { Text(spec.label, maxLines = 1) },
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(padding),
        ) {
            composable(Routes.HOME) {
                HomeScreen(
                    vm = vm,
                    onListingClick = { navController.navigate(Routes.detail(it)) },
                    onCategoryClick = { navController.navigate(Routes.category(it)) },
                )
            }
            composable(Routes.SEARCH) {
                SearchScreen(
                    vm = vm,
                    onListingClick = { navController.navigate(Routes.detail(it)) },
                )
            }
            composable(Routes.POST_AD) {
                PostAdScreen(
                    vm = vm,
                    onRequireLogin = { navController.navigate(Routes.AUTH) },
                    onPublished = { navController.navigate(Routes.detail(it)) },
                )
            }
            composable(Routes.CHATS) {
                ChatsScreen(
                    vm = vm,
                    onRequireLogin = { navController.navigate(Routes.AUTH) },
                    onOpenChat = { conversationId, listingId, otherUserId ->
                        navController.navigate(Routes.chat(conversationId, listingId, otherUserId))
                    },
                )
            }
            composable(Routes.PROFILE) {
                ProfileScreen(
                    vm = vm,
                    onRequireLogin = { navController.navigate(Routes.AUTH) },
                    onMyAds = { navController.navigate(Routes.MY_ADS) },
                    onFavorites = { navController.navigate(Routes.FAVORITES) },
                )
            }
            composable(Routes.AUTH) {
                AuthScreen(vm = vm, onDone = { navController.popBackStack() })
            }
            composable(Routes.MY_ADS) {
                MyAdsScreen(
                    vm = vm,
                    onBack = { navController.popBackStack() },
                    onListingClick = { navController.navigate(Routes.detail(it)) },
                )
            }
            composable(Routes.FAVORITES) {
                FavoritesScreen(
                    vm = vm,
                    onBack = { navController.popBackStack() },
                    onListingClick = { navController.navigate(Routes.detail(it)) },
                )
            }
            composable(
                Routes.CATEGORY,
                arguments = listOf(navArgument("categoryId") { type = NavType.StringType }),
            ) { entry ->
                val categoryId = entry.arguments?.getString("categoryId") ?: "other"
                CategoryScreen(
                    vm = vm,
                    categoryId = categoryId,
                    onBack = { navController.popBackStack() },
                    onListingClick = { navController.navigate(Routes.detail(it)) },
                )
            }
            composable(
                Routes.DETAIL,
                arguments = listOf(navArgument("listingId") { type = NavType.LongType }),
            ) { entry ->
                val listingId = entry.arguments?.getLong("listingId") ?: return@composable
                ListingDetailScreen(
                    vm = vm,
                    listingId = listingId,
                    onBack = { navController.popBackStack() },
                    onRequireLogin = { navController.navigate(Routes.AUTH) },
                    onOpenChat = { conversationId, lId, otherUserId ->
                        navController.navigate(Routes.chat(conversationId, lId, otherUserId))
                    },
                )
            }
            composable(
                Routes.CHAT,
                arguments = listOf(
                    navArgument("conversationId") { type = NavType.StringType },
                    navArgument("listingId") { type = NavType.LongType },
                    navArgument("otherUserId") { type = NavType.LongType },
                ),
            ) { entry ->
                val conversationId = entry.arguments?.getString("conversationId") ?: return@composable
                val listingId = entry.arguments?.getLong("listingId") ?: return@composable
                val otherUserId = entry.arguments?.getLong("otherUserId") ?: return@composable
                ChatScreen(
                    vm = vm,
                    conversationId = conversationId,
                    listingId = listingId,
                    otherUserId = otherUserId,
                    onBack = { navController.popBackStack() },
                )
            }
        }
    }
}
