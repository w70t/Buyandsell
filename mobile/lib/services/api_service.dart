import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/models.dart';

/// One place for every backend call.
class ApiService {
  ApiService(this._client);

  final ApiClient _client;
  Dio get _dio => _client.dio;

  // ---- Auth ----
  Future<UserModel> register(String name, String phone, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'password': password,
    });
    return _saveAuth(res.data as Map<String, dynamic>);
  }

  Future<UserModel> login(String phone, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return _saveAuth(res.data as Map<String, dynamic>);
  }

  Future<UserModel> _saveAuth(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _client.tokens.save(
      access: tokens['access_token'] as String,
      refresh: tokens['refresh_token'] as String,
    );
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> me() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ---- Categories ----
  Future<List<Category>> categories() async {
    final res = await _dio.get('/categories');
    return (res.data as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Listings ----
  Future<PageResult<Listing>> listings({
    String? q,
    int? categoryId,
    String? governorate,
    int? minPrice,
    int? maxPrice,
    String sort = 'recent',
    int page = 1,
    int size = 20,
  }) async {
    final res = await _dio.get('/listings', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (categoryId != null) 'category_id': categoryId,
      if (governorate != null) 'governorate': governorate,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      'sort': sort,
      'page': page,
      'size': size,
    });
    return PageResult.fromJson(
      res.data as Map<String, dynamic>,
      (e) => Listing.fromJson(e),
    );
  }

  Future<List<Listing>> myListings() async {
    final res = await _dio.get('/listings/mine');
    return (res.data as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Listing> listing(int id) async {
    final res = await _dio.get('/listings/$id');
    return Listing.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Listing> createListing({
    required String title,
    required String description,
    required int price,
    required bool negotiable,
    required String condition,
    required int categoryId,
    required String governorate,
    String city = '',
  }) async {
    final res = await _dio.post('/listings', data: {
      'title': title,
      'description': description,
      'price': price,
      'negotiable': negotiable,
      'condition': condition,
      'category_id': categoryId,
      'governorate': governorate,
      'city': city,
    });
    return Listing.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Listing> uploadImage(int listingId, String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/listings/$listingId/images', data: form);
    return Listing.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteListing(int id) async {
    await _dio.delete('/listings/$id');
  }

  // ---- Favorites ----
  Future<List<Listing>> favorites() async {
    final res = await _dio.get('/favorites');
    return (res.data as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<int>> favoriteIds() async {
    final res = await _dio.get('/favorites/ids');
    return (res.data as List).map((e) => e as int).toList();
  }

  Future<void> addFavorite(int id) async => _dio.post('/favorites/$id');

  Future<void> removeFavorite(int id) async => _dio.delete('/favorites/$id');

  // ---- Messages ----
  Future<List<Conversation>> conversations() async {
    final res = await _dio.get('/messages/conversations');
    return (res.data as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> conversation(String conversationId) async {
    final res = await _dio.get('/messages/conversation/$conversationId');
    return (res.data as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Message> sendMessage(int listingId, int receiverId, String body) async {
    final res = await _dio.post('/messages', data: {
      'listing_id': listingId,
      'receiver_id': receiverId,
      'body': body,
    });
    return Message.fromJson(res.data as Map<String, dynamic>);
  }
}
