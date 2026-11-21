import 'package:flutter/material.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/services/marketplace_state.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MarketplaceScope.of(context);
    final favorites = state.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const Center(child: Text('لم تحفظ أي إعلانات بعد'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final listing = favorites[index];
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetworkImageWithLoader(
                              listing.imageUrl,
                              radius: 0,
                            ),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: IconButton.filled(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    state.toggleFavorite(listing.id),
                                icon: const Icon(Icons.favorite,
                                    color: Colors.red),
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
                                  color: Color(0xFF075E54),
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
