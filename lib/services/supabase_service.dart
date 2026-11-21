import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing_model.dart';

class SupabaseService {
  SupabaseService._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (_url.isEmpty && _anonKey.isEmpty) return;
    if (_url.isEmpty || _anonKey.isEmpty) {
      throw StateError(
        'Set both SUPABASE_URL and SUPABASE_ANON_KEY to enable Supabase.',
      );
    }

    await Supabase.initialize(url: _url, publishableKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => isConfigured ? client.auth.currentUser : null;

  static Future<void> signOut() async {
    if (!isConfigured) return;
    await client.auth.signOut();
  }

  static Future<bool> signIn(String email, String password) async {
    final response = await client.auth
        .signInWithPassword(email: email.trim(), password: password);
    final user = response.user;
    if (user == null) return false;
    final profile = await client
        .from('profiles')
        .select('is_active')
        .eq('id', user.id)
        .maybeSingle();
    if (profile == null || profile['is_active'] != true) {
      await client.auth.signOut();
      return false;
    }
    return true;
  }

  static Future<bool> signUp(String email, String password) async {
    final response =
        await client.auth.signUp(email: email.trim(), password: password);
    return response.user != null;
  }

  static Future<bool> get hasStaffAccess async {
    final user = currentUser;
    if (user == null) return false;
    final profile = await client
        .from('profiles')
        .select('role,is_active')
        .eq('id', user.id)
        .maybeSingle();
    return profile != null &&
        profile['is_active'] == true &&
        const {'admin', 'supervisor'}.contains(profile['role']);
  }

  static Future<List<ListingModel>> loadListings() async {
    final rows = await client
        .from('listings')
        .select()
        .eq('status', 'approved')
        .order('is_featured', ascending: false);
    return rows.map(_listingFromRow).toList();
  }

  static Future<List<ListingModel>> loadMyListings() async {
    final user = currentUser;
    if (user == null) return [];
    final rows = await client
        .from('listings')
        .select()
        .eq('created_by', user.id)
        .order('created_at', ascending: false);
    return rows.map(_listingFromRow).toList();
  }

  static Future<List<Map<String, Object?>>> loadAdminListings() async {
    final rows = await client
        .from('listings')
        .select()
        .order('created_at', ascending: false);
    return rows.cast<Map<String, Object?>>();
  }

  static Future<void> createListing(ListingModel listing) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in before creating a listing.');
    await client.from('listings').insert({
      'id': listing.id,
      'title': listing.title,
      'category': listing.category,
      'location': listing.location,
      'price': listing.price,
      'image_url': listing.imageUrl,
      'description': listing.description,
      'created_by': user.id,
      'status': 'pending',
    });
  }

  static Future<String> uploadListingImage(String filePath) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in before uploading an image.');
    final file = File(filePath);
    final objectPath =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await client.storage.from('listing-images').upload(objectPath, file);
    return client.storage.from('listing-images').getPublicUrl(objectPath);
  }

  static Future<void> moderateListing(String id, String status) async {
    await client.rpc('moderate_listing', params: {
      'target_listing_id': id,
      'target_status': status,
    });
  }

  static Future<void> deleteListing(String id) async {
    await client.from('listings').delete().eq('id', id);
  }

  static Future<List<Map<String, Object?>>> loadProfiles() async {
    final rows = await client
        .from('profiles')
        .select('id,email,role,is_active,created_at')
        .order('created_at', ascending: false);
    return rows.cast<Map<String, Object?>>();
  }

  static Future<void> setProfileActive(String id, bool isActive) async {
    await client.rpc('set_profile_active', params: {
      'target_user_id': id,
      'active': isActive,
    });
  }

  static Future<List<Map<String, Object?>>> loadOrders() async {
    final rows = await client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    return rows.cast<Map<String, Object?>>();
  }

  static Future<void> setOrderStatus(String id, String status) async {
    await client.rpc('set_order_status', params: {
      'target_order_id': id,
      'target_status': status,
    });
  }

  static Future<void> createOrder({
    required String title,
    required int total,
  }) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in before placing an order.');
    await client.from('orders').insert({
      'user_id': user.id,
      'title': title,
      'total': total,
      'status': 'قيد المراجعة',
    });
  }

  static ListingModel _listingFromRow(Map<String, dynamic> row) => ListingModel(
        id: row['id'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        location: row['location'] as String,
        price: (row['price'] as num).toInt(),
        imageUrl: row['image_url'] as String? ?? '',
        description: row['description'] as String? ?? '',
        isFeatured: row['is_featured'] as bool? ?? false,
      );
}
