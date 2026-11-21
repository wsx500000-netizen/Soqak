import 'package:flutter/material.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/models/listing_model.dart';
import 'package:shop/services/marketplace_state.dart';
import 'package:shop/services/supabase_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MarketplaceScope.of(context);
    final listings = state.cart.keys
        .map((id) {
          return state.listingById(id);
        })
        .whereType<ListingModel>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: listings.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('سلتك فارغة'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      final quantity = state.cart[listing.id] ?? 1;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: NetworkImageWithLoader(
                              listing.imageUrl,
                              radius: 8,
                              width: 58,
                              height: 58,
                            ),
                          ),
                          title: Text(listing.title),
                          subtitle: Text(
                              '${listing.price * quantity} ر.س × $quantity'),
                          trailing: IconButton(
                            onPressed: () => state.removeFromCart(listing.id),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي'),
                          Text('${state.cartTotal} ر.س',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await state.placeOrder();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'تعذر إنشاء الطلب. سجّل الدخول وحاول مجددًا.'),
                              ),
                            );
                            return;
                          }
                          if (!context.mounted) return;
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('تم تأكيد الطلب'),
                              content: Text(SupabaseService.isConfigured
                                  ? 'تم حفظ الطلب في حسابك. الدفع الإلكتروني غير مفعّل.'
                                  : 'تم حفظ الطلب محلياً على الجهاز.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('حسناً'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('إتمام الطلب'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
