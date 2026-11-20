import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/listing_model.dart';

class MarketplaceState extends ChangeNotifier {
  MarketplaceState();

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
      description: 'سيارة نظيفة بالكامل، صيانة دورية وأولوية للاستخدام العائلي.',
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

  int get cartTotal => cart.entries.fold(
        0,
        (sum, entry) {
          final listing = listings.firstWhere(
            (listing) => listing.id == entry.key,
            orElse: () => myListings.firstWhere(
              (listing) => listing.id == entry.key,
              orElse: () => ListingModel(
                id: '',
                title: '',
                category: '',
                location: '',
                price: 0,
                imageUrl: '',
              ),
            ),
          );
          return sum + listing.price * entry.value;
        },
      );

  void toggleFavorite(String id) {
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
    } else {
      favoriteIds.add(id);
    }
    notifyListeners();
  }

  void addToCart(ListingModel listing) {
    cart.update(listing.id, (quantity) => quantity + 1,
        ifAbsent: () => 1);
    notifyListeners();
  }

  void removeFromCart(String id) {
    cart.remove(id);
    notifyListeners();
  }

  void addListing(ListingModel listing) {
    myListings.insert(0, listing);
    listings.insert(0, listing);
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
    return context.dependOnInheritedWidgetOfExactType<MarketplaceScope>()!.notifier!;
  }
}
