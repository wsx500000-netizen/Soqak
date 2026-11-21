import 'package:flutter/material.dart';
import 'package:shop/services/local_database.dart';
import 'package:shop/services/supabase_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, Object?>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
  }

  Future<List<Map<String, Object?>>> _loadOrders() async {
    if (SupabaseService.isConfigured) {
      return SupabaseService.loadOrders();
    }
    final db = await LocalDatabase.instance.database;
    return db.query('orders', orderBy: 'createdAt DESC');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل الطلبات'));
          }
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('لا توجد طلبات بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final row = rows[index];
              return _OrderCard(
                title: row['title'] as String,
                status: row['status'] as String,
                date:
                    'إجمالي الطلب: ${row['total']} ر.س · ${row[SupabaseService.isConfigured ? 'created_at' : 'createdAt']}',
                color: const Color(0xFF0B5D5B),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.title,
    required this.status,
    required this.date,
    required this.color,
  });

  final String title;
  final String status;
  final String date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    Text(status, style: TextStyle(color: color, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(date, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
