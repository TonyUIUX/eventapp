import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueDashboardScreen extends ConsumerWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Revenue & Growth', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          // Calculate stats
          double totalRevenue = 0;
          double monthRevenue = 0;
          double todayRevenue = 0;
          int totalCount = docs.length;

          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final startOfToday = DateTime(now.year, now.month, now.day);

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0) / 100.0;
            final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            totalRevenue += amount;
            if (date.isAfter(startOfMonth)) monthRevenue += amount;
            if (date.isAfter(startOfToday)) todayRevenue += amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatCard(title: 'Life-time Revenue', value: '₹${totalRevenue.toStringAsFixed(2)}', icon: Icons.payments, color: Colors.green),
                    const SizedBox(width: 16),
                    _StatCard(title: 'This Month', value: '₹${monthRevenue.toStringAsFixed(2)}', icon: Icons.calendar_month, color: Colors.blue),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Today', value: '₹${todayRevenue.toStringAsFixed(2)}', icon: Icons.today, color: Colors.orange),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Total Transactions', value: '$totalCount', icon: Icons.receipt_long, color: Colors.purple),
                  ],
                ),
                const SizedBox(height: 48),
                const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length > 20 ? 20 : docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final amount = (data['amount'] ?? 0) / 100.0;
                      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                        ),
                        title: Text('Payment from ${data['userId']?.toString().substring(0, 8) ?? 'User'}'),
                        subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date)),
                        trailing: Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
