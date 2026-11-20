import 'package:flutter/material.dart';

import '../../models/listing_model.dart';
import '../../services/marketplace_state.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  String _category = 'هواتف';

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة إعلان'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40),
                  SizedBox(height: 8),
                  Text('إضافة صور الإعلان'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'عنوان الإعلان',
                hintText: 'مثال: آيفون بحالة ممتازة',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'أدخل العنوان' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'القسم'),
              items: const [
                'هواتف',
                'سيارات',
                'عقارات',
                'اثاث',
                'ساعات',
                'الكترونيات',
              ]
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر',
                suffixText: 'ر.س',
              ),
              validator: (value) =>
                  int.tryParse(value ?? '') == null ? 'أدخل سعراً صحيحاً' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'المدينة أو الحي'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'أدخل الموقع' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'تفاصيل الإعلان',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final listing = ListingModel(
                  id: 'listing-${DateTime.now().millisecondsSinceEpoch}',
                  title: _title.text.trim(),
                  category: _category,
                  location: _location.text.trim(),
                  price: int.parse(_price.text),
                  description: _description.text.trim(),
                  imageUrl:
                      'https://images.unsplash.com/photo-1472851294608-062f824d29cc',
                );
                MarketplaceScope.of(context).addListing(listing);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نشر إعلانك بنجاح')),
                );
              },
              child: const Text('نشر الإعلان'),
            ),
          ],
        ),
      ),
    );
  }
}
