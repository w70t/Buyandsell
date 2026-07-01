package com.iraqsouq.app.ui.nav

object Routes {
    const val AUTH = "auth"
    const val HOME = "home"
    const val SEARCH = "search"
    const val POST_AD = "post_ad"
    const val MY_ADS = "my_ads"
    const val FAVORITES = "favorites"
    const val CHATS = "chats"
    const val PROFILE = "profile"

    // category/{categoryId}
    const val CATEGORY = "category/{categoryId}"
    fun category(categoryId: String) = "category/$categoryId"

    // detail/{listingId}
    const val DETAIL = "detail/{listingId}"
    fun detail(listingId: Long) = "detail/$listingId"

    // chat/{conversationId}/{listingId}/{listingTitle}/{otherUserId}
    const val CHAT = "chat/{conversationId}/{listingId}/{otherUserId}"
    fun chat(conversationId: String, listingId: Long, otherUserId: Long) =
        "chat/$conversationId/$listingId/$otherUserId"
}

/** Bottom navigation destinations. */
enum class BottomTab(val route: String) {
    Home(Routes.HOME),
    Search(Routes.SEARCH),
    PostAd(Routes.POST_AD),
    Chats(Routes.CHATS),
    Profile(Routes.PROFILE),
}
