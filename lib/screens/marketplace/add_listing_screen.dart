import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/listing_model.dart';
import '../../services/marketplace_state.dart';
import '../../services/supabase_service.dart';

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
  String _imageUrl =
      'https://images.unsplash.com/photo-1472851294608-062f824d29cc';
  bool _isPickingImage = false;
  bool _isSubmitting = false;

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
            InkWell(
              onTap: _isPickingImage
                  ? null
                  : () async {
                      setState(() => _isPickingImage = true);
                      try {
                        final file = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (!mounted) return;
                        setState(() {
                          if (file != null) _imageUrl = file.path;
                        });
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر فتح معرض الصور. حاول مجددًا.'),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _isPickingImage = false);
                        }
                      }
                    },
              child: Container(
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isPickingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _imageUrl.startsWith('/')
                        ? Image.file(File(_imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.image)))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo_outlined, size: 40),
                              SizedBox(height: 8),
                              Text('إضافة صور الإعلان'),
                            ],
                          ),
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
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'أدخل سعراً صحيحاً'
                  : null,
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
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final marketplace = MarketplaceScope.of(context);
                      setState(() => _isSubmitting = true);
                      try {
                        var imageUrl = _imageUrl;
                        if (_imageUrl.startsWith('/')) {
                          if (SupabaseService.isConfigured) {
                            imageUrl = await SupabaseService.uploadListingImage(
                                _imageUrl);
                          } else {
                            imageUrl = await _saveImageLocally(_imageUrl);
                          }
                        }
                        final listing = ListingModel(
                          id: 'listing-${DateTime.now().microsecondsSinceEpoch}',
                          title: _title.text.trim(),
                          category: _category,
                          location: _location.text.trim(),
                          price: int.parse(_price.text),
                          description: _description.text.trim(),
                          imageUrl: imageUrl,
                        );
                        await marketplace.addListing(listing);
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تعذر إرسال الإعلان. تحقق من اتصالك وحاول مجددًا.'),
                          ),
                        );
                        return;
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('تم إرسال إعلانك للمراجعة قبل النشر')),
                      );
                    },
              child: Text(_isSubmitting ? 'جارٍ الإرسال...' : 'إرسال للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _saveImageLocally(String sourcePath) async {
    final documents = await getApplicationDocumentsDirectory();
    final images = Directory(path.join(documents.path, 'listing-images'));
    await images.create(recursive: true);
    final extension = path.extension(sourcePath);
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    return (await File(sourcePath).copy(path.join(images.path, fileName))).path;
  }
}
