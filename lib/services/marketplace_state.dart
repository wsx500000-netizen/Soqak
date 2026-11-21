import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import '../models/listing_model.dart';
import 'local_database.dart';
import 'supabase_service.dart';

class MarketplaceState extends ChangeNotifier {
  MarketplaceState() {
    _load();
  }

  bool isLoading = true;
  String? loadError;

  final List<ListingModel> listings = [
    ListingModel(
      id: 'listing-1',
      title: 'آيفون 15 برو 256 جيجا',
      category: 'هواتف',
      location: 'رياض',
      price: 4200,
      imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569',
      description: 'هاتف بحالة ممتازة مع كرتون الشاحن والعلبة الأصلية.',
      isFeatured: true,
    ),
    ListingModel(
      id: 'listing-2',
      title: 'سيارة تويوتا كورولا 2022',
      category: 'سيارات',
      location: 'جدة',
      price: 68000,
      imageUrl: 'https://images.unsplash.com/photo-1623869675786-d5d3d9c5c4e1',
      description:
          'سيارة نظيفة بالكامل، صيانة دورية وأولوية للاستخدام العائلي.',
      isFeatured: true,
    ),
    ListingModel(
      id: 'listing-3',
      title: 'شقة فاخرة للإيجار',
      category: 'عقارات',
      location: 'الدمام',
      price: 35000,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
      description: 'شقة مؤثثة بالكامل بموقع مميز وقريبة من الخدمات.',
    ),
    ListingModel(
      id: 'listing-4',
      title: 'كرسي مكتبي مريح',
      category: 'اثاث',
      location: 'الرياض',
      price: 450,
      imageUrl: 'https://images.unsplash.com/photo-1505797149-43b0069ec26b',
      description: 'كرسي مكتب شبكي بحالة جيدة مع ضمان لمدة شهر.',
    ),
    ListingModel(
      id: 'listing-5',
      title: 'ساعة أبل ووتش سيريس 9',
      category: 'ساعات',
      location: 'مكة',
      price: 1600,
      imageUrl: 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d',
      description: 'ساعة بحالة شبه جديدة مع علبة وسلك الشحن.',
    ),
  ];

  final Set<String> favoriteIds = {};
  final Map<String, int> cart = {};
  final List<ListingModel> myListings = [];

  Future<void> _load() async {
    try {
      if (SupabaseService.isConfigured) {
        listings.clear();
        myListings.clear();
        listings..addAll(await SupabaseService.loadListings());
        myListings..addAll(await SupabaseService.loadMyListings());
        final db = await LocalDatabase.instance.database;
        await _loadLocalPreferences(db);
        loadError = null;
        return;
      }

      final db = await LocalDatabase.instance.database;
      final rows = await db.query('listings', orderBy: 'isFeatured DESC');

      if (rows.isEmpty) {
        await _seedDatabase(db);
        listings
          ..clear()
          ..addAll(await _readListings(db));
      } else {
        listings
          ..clear()
          ..addAll(await _readListings(db));
      }

      myListings
        ..clear()
        ..addAll(await _readListings(db, mineOnly: true));

      await _loadLocalPreferences(db);
      loadError = null;
    } catch (error) {
      if (SupabaseService.isConfigured) {
        listings.clear();
        myListings.clear();
        loadError = 'تعذر الاتصال بسوقك السحابي';
      } else {
        loadError = 'تعذر تحميل البيانات المحفوظة';
      }
      debugPrint('Marketplace data load failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalPreferences(DatabaseExecutor db) async {
    final favoriteRows = await db.query('favorites');
    favoriteIds
      ..clear()
      ..addAll(favoriteRows.map((row) => row['listingId'] as String));

    final cartRows = await db.query('cart');
    cart
      ..clear()
      ..addEntries(cartRows.map(
        (row) => MapEntry(row['listingId'] as String, row['quantity'] as int),
      ));
  }

  Future<void> _seedDatabase(Database db) async {
    await db.transaction((txn) async {
      for (final listing in listings) {
        await txn.insert('listings', _listingRow(listing, isMine: false));
      }
    });
  }

  Future<List<ListingModel>> _readListings(DatabaseExecutor db,
      {bool mineOnly = false}) async {
    final rows = await db.query(
      'listings',
      where: mineOnly ? 'isMine = 1' : "status = 'approved'",
      orderBy: 'isFeatured DESC',
    );
    return rows.map((row) => _listingFromRow(row)).toList();
  }

  Map<String, Object?> _listingRow(ListingModel listing,
          {required bool isMine, String status = 'approved'}) =>
      {
        'id': listing.id,
        'title': listing.title,
        'category': listing.category,
        'location': listing.location,
        'price': listing.price,
        'imageUrl': listing.imageUrl,
        'description': listing.description,
        'isFeatured': listing.isFeatured ? 1 : 0,
        'isMine': isMine ? 1 : 0,
        'status': status,
      };

  ListingModel _listingFromRow(Map<String, Object?> row) => ListingModel(
        id: row['id'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        location: row['location'] as String,
        price: row['price'] as int,
        imageUrl: row['imageUrl'] as String,
        description: row['description'] as String,
        isFeatured: row['isFeatured'] == 1,
      );

  List<ListingModel> get favorites {
    final result = <ListingModel>[];
    for (final listing in [...myListings, ...listings]) {
      if (favoriteIds.contains(listing.id) &&
          result.every((item) => item.id != listing.id)) {
        result.add(listing);
      }
    }
    return result;
  }

  int get cartCount => cart.values.fold(0, (sum, quantity) => sum + quantity);

  ListingModel? listingById(String id) {
    for (final listing in [...listings, ...myListings]) {
      if (listing.id == id) return listing;
    }
    return null;
  }

  int get cartTotal => cart.entries.fold(
        0,
        (sum, entry) {
          final listing = listingById(entry.key);
          return sum + (listing?.price ?? 0) * entry.value;
        },
      );

  void toggleFavorite(String id) {
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
    } else {
      favoriteIds.add(id);
    }
    _persistFavorite(id);
    notifyListeners();
  }

  Future<void> _persistFavorite(String id) async {
    final db = await LocalDatabase.instance.database;
    if (favoriteIds.contains(id)) {
      await db.insert('favorites', {'listingId': id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('favorites', where: 'listingId = ?', whereArgs: [id]);
    }
  }

  void addToCart(ListingModel listing) {
    cart.update(listing.id, (quantity) => quantity + 1, ifAbsent: () => 1);
    _persistCartItem(listing.id);
    notifyListeners();
  }

  void removeFromCart(String id) {
    cart.remove(id);
    _persistRemoveCartItem(id);
    notifyListeners();
  }

  Future<void> _persistCartItem(String id) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      'cart',
      {'listingId': id, 'quantity': cart[id]},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _persistRemoveCartItem(String id) async {
    final db = await LocalDatabase.instance.database;
    await db.delete('cart', where: 'listingId = ?', whereArgs: [id]);
  }

  Future<void> addListing(ListingModel listing) async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.createListing(listing);
      myListings.insert(0, listing);
      notifyListeners();
      return;
    }
    await _persistListing(listing);
    myListings.insert(0, listing);
    notifyListeners();
  }

  Future<void> _persistListing(ListingModel listing) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      'listings',
      _listingRow(listing, isMine: true, status: 'pending'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> refreshListings() async {
    if (SupabaseService.isConfigured) {
      listings
        ..clear()
        ..addAll(await SupabaseService.loadListings());
      myListings
        ..clear()
        ..addAll(await SupabaseService.loadMyListings());
      loadError = null;
      notifyListeners();
      return;
    }

    final db = await LocalDatabase.instance.database;
    final approvedListings = await _readListings(db);
    listings
      ..clear()
      ..addAll(approvedListings);
    myListings
      ..clear()
      ..addAll(await _readListings(db, mineOnly: true));
    loadError = null;
    notifyListeners();
  }

  Future<void> retryLoading() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    await _load();
  }

  Future<void> placeOrder() async {
    if (cart.isEmpty) return;
    final items = [...listings, ...myListings]
        .where((listing) => cart.containsKey(listing.id))
        .toList();
    final titles = items.map((listing) => listing.title).join('، ');
    if (SupabaseService.isConfigured) {
      await SupabaseService.createOrder(
        title: titles.isEmpty ? 'طلب سوقك' : titles,
        total: cartTotal,
      );
      final db = await LocalDatabase.instance.database;
      await db.delete('cart');
      cart.clear();
      notifyListeners();
      return;
    }

    final db = await LocalDatabase.instance.database;
    await db.insert(
      'orders',
      {
        'id': 'order-${DateTime.now().millisecondsSinceEpoch}',
        'title': titles.isEmpty ? 'طلب سوقك' : titles,
        'status': 'قيد المراجعة',
        'createdAt': DateTime.now().toIso8601String(),
        'total': cartTotal,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete('cart');
    cart.clear();
    notifyListeners();
  }
}

class MarketplaceScope extends InheritedNotifier<MarketplaceState> {
  const MarketplaceScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static MarketplaceState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MarketplaceScope>()!
        .notifier!;
  }
}
