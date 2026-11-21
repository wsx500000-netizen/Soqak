import 'package:flutter/material.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/services/marketplace_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  String _category = 'الكل';
  String _location = 'الكل';

  @override
  Widget build(BuildContext context) {
    final state = MarketplaceScope.of(context);
    final results = state.listings.where((listing) {
      final matchesQuery = _query.isEmpty ||
          listing.title.contains(_query) ||
          listing.category.contains(_query);
      final matchesCategory =
          _category == 'الكل' || listing.category == _category;
      final matchesLocation =
          _location == 'الكل' || listing.location == _location;
      return matchesQuery && matchesCategory && matchesLocation;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث والفلاتر'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'ابحث عن سيارة، هاتف، عقار...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final category in [
                  'الكل',
                  'سيارات',
                  'عقارات',
                  'هواتف',
                  'اثاث',
                  'ساعات',
                  'الكترونيات',
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(
                labelText: 'المدينة',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: ['الكل', 'الرياض', 'جدة', 'الدمام', 'مكة']
                  .map((location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _location = value ?? 'الكل'),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('لا توجد نتائج مطابقة'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final listing = results[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE8E8E8)),
                        ),
                        leading: NetworkImageWithLoader(
                          listing.imageUrl,
                          radius: 8,
                          width: 64,
                          height: 64,
                        ),
                        title: Text(listing.title),
                        subtitle:
                            Text('${listing.location} • ${listing.price} ر.س'),
                        trailing: IconButton(
                          onPressed: () => state.toggleFavorite(listing.id),
                          icon: Icon(
                            state.favoriteIds.contains(listing.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
