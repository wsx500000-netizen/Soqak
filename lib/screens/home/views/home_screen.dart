import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/listing_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/marketplace_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MarketplaceScope.of(context);
    final categories = [
      ('سيارات', Icons.directions_car_filled_outlined),
      ('عقارات', Icons.home_work_outlined),
      ('هواتف', Icons.phone_android_outlined),
      ('اثاث', Icons.weekend_outlined),
      ('الكترونيات', Icons.devices_outlined),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, addListingScreenRoute),
        icon: const Icon(Icons.add),
        label: const Text('إضافة إعلان'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  defaultPadding, defaultPadding, defaultPadding, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اعثر على ما تحتاجه',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'آلاف الإعلانات القريبة منك',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.storefront_outlined,
                        color: Colors.white, size: 44),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () =>
                            Navigator.pushNamed(context, searchScreenRoute),
                        child: Container(
                          width: 82,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(category.$2, color: primaryColor),
                              const SizedBox(height: 6),
                              Text(category.$1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(
                'إعلانات مميزة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _ListingCard(listing: state.listings[index]),
                childCount: state.listings.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final state = MarketplaceScope.of(context);
    final isFavorite = state.favoriteIds.contains(listing.id);

    return InkWell(
      onTap: () => _showDetails(context, listing),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: listing.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFFF1F2F6)),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFF1F2F6)),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => state.toggleFavorite(listing.id),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${listing.price} ر.س',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, ListingModel listing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final state = MarketplaceScope.of(context);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: listing.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(listing.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${listing.price} ر.س',
                  style: const TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(listing.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, chatScreenRoute),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('محادثة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.addToCart(listing);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت الإضافة للسلة')),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('إضافة للسلة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
