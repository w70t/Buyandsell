class UserModel {
  final int id;
  final String name;
  final String phone;
  final String? role;

  UserModel({required this.id, required this.name, required this.phone, this.role});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String?,
      );

  bool get isAdmin => role == 'admin';
}

class Category {
  final int id;
  final String slug;
  final String nameAr;
  final String subtitleAr;
  final String icon;

  Category({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.subtitleAr,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        slug: j['slug'] as String,
        nameAr: j['name_ar'] as String,
        subtitleAr: (j['subtitle_ar'] ?? '') as String,
        icon: (j['icon'] ?? 'widgets') as String,
      );
}

class ListingImage {
  final int id;
  final String url;
  final int position;

  ListingImage({required this.id, required this.url, required this.position});

  factory ListingImage.fromJson(Map<String, dynamic> j) => ListingImage(
        id: j['id'] as int,
        url: j['url'] as String,
        position: (j['position'] ?? 0) as int,
      );
}

class Listing {
  final int id;
  final String title;
  final String description;
  final int price;
  final String currency;
  final bool negotiable;
  final String condition;
  final String governorate;
  final String city;
  final String status;
  final int views;
  final DateTime createdAt;
  final Category category;
  final UserModel seller;
  final List<ListingImage> images;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.negotiable,
    required this.condition,
    required this.governorate,
    required this.city,
    required this.status,
    required this.views,
    required this.createdAt,
    required this.category,
    required this.seller,
    required this.images,
  });

  String? get cover => images.isNotEmpty ? images.first.url : null;

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String,
        price: j['price'] as int,
        currency: (j['currency'] ?? 'IQD') as String,
        negotiable: (j['negotiable'] ?? false) as bool,
        condition: (j['condition'] ?? 'used') as String,
        governorate: j['governorate'] as String,
        city: (j['city'] ?? '') as String,
        status: (j['status'] ?? 'active') as String,
        views: (j['views'] ?? 0) as int,
        createdAt: DateTime.parse(j['created_at'] as String),
        category: Category.fromJson(j['category'] as Map<String, dynamic>),
        seller: UserModel.fromJson(j['seller'] as Map<String, dynamic>),
        images: ((j['images'] ?? []) as List)
            .map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PageResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;

  PageResult({required this.items, required this.total, required this.page, required this.size});

  factory PageResult.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) parse) {
    return PageResult(
      items: ((j['items'] ?? []) as List).map((e) => parse(e as Map<String, dynamic>)).toList(),
      total: (j['total'] ?? 0) as int,
      page: (j['page'] ?? 1) as int,
      size: (j['size'] ?? 20) as int,
    );
  }
}

class Conversation {
  final String conversationId;
  final int listingId;
  final String listingTitle;
  final int otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;

  Conversation({
    required this.conversationId,
    required this.listingId,
    required this.listingTitle,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        conversationId: j['conversation_id'] as String,
        listingId: j['listing_id'] as int,
        listingTitle: j['listing_title'] as String,
        otherUserId: j['other_user_id'] as int,
        otherUserName: j['other_user_name'] as String,
        lastMessage: j['last_message'] as String,
        lastAt: DateTime.parse(j['last_at'] as String),
        unread: (j['unread'] ?? 0) as int,
      );
}

class Message {
  final int id;
  final String conversationId;
  final int listingId;
  final int senderId;
  final int receiverId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.listingId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as String,
        listingId: j['listing_id'] as int,
        senderId: j['sender_id'] as int,
        receiverId: j['receiver_id'] as int,
        body: j['body'] as String,
        isRead: (j['is_read'] ?? false) as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
