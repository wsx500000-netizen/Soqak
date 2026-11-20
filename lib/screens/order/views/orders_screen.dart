import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderCard(
            title: 'آيفون 15 برو 256 جيجا',
            status: 'قيد التوصيل',
            date: 'اليوم',
            color: const Color(0xFF075E54),
          ),
          const SizedBox(height: 12),
          _OrderCard(
            title: 'ساعة أبل ووتش سيريس 9',
            status: 'تم التسليم',
            date: 'قبل 3 أيام',
            color: Colors.green,
          ),
        ],
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
                child: Text(status,
                    style: TextStyle(color: color, fontSize: 12)),
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
