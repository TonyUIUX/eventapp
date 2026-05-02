import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/firestore_admin_service.dart';
import '../providers/admin_providers.dart';
import 'event_form_screen.dart';
import 'login_screen.dart';
import 'revenue_dashboard_screen.dart';
import 'pricing_management_screen.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final FirestoreAdminService _adminService = FirestoreAdminService();
  int _selectedIndex = 0;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _handleDelete(BuildContext context, EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Deletion'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _adminService.deleteEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted.')));
      }
    }
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Global Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', hintText: 'Breaking News!')),
            const SizedBox(height: 12),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Message', hintText: 'Free posting period extended...'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || bodyController.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('broadcasts').add({
                'title': titleController.text.trim(),
                'body': bodyController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
                'status': 'pending',
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast queued successfully.')));
            },
            child: const Text('Dispatch Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final configAsync = ref.watch(adminConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KochiGo Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    configAsync.maybeWhen(
                      data: (config) => config.maintenanceMode 
                          ? const Text('MAINTENANCE ON', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Events Feed'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: Text('Revenue'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Pricing & Config'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _buildCurrentScreen(isWide),
          ),
        ],
      ),
      bottomNavigationBar: !isWide ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Revenue'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ) : null,
    );
  }

  Widget _buildCurrentScreen(bool isWide) {
    switch (_selectedIndex) {
      case 0:
        return _EventsDashboardView(
          adminService: _adminService,
          logout: _logout,
          isWide: isWide,
          showBroadcast: () => _showBroadcastDialog(context),
          handleDelete: (event) => _handleDelete(context, event),
        );
      case 1:
        return const RevenueDashboardScreen();
      case 2:
        return const PricingManagementScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}

class _EventsDashboardView extends StatelessWidget {
  final FirestoreAdminService adminService;
  final VoidCallback logout;
  final bool isWide;
  final VoidCallback showBroadcast;
  final Function(EventModel) handleDelete;

  const _EventsDashboardView({
    required this.adminService,
    required this.logout,
    required this.isWide,
    required this.showBroadcast,
    required this.handleDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          title: const Text('Events Management', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (!isWide) IconButton(icon: const Icon(Icons.logout), onPressed: logout),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: showBroadcast,
                icon: const Icon(Icons.campaign_outlined, size: 18),
                label: const Text('Broadcast'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade800,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StreamBuilder<List<EventModel>>(
              stream: adminService.getAllEventsStream(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final active = snapshot.data?.where((e) => e.status == 'active').length ?? 0;
                final pending = snapshot.data?.where((e) => e.status == 'under_review').length ?? 0;
                
                return Row(
                  children: [
                    _StatCard(title: 'Total Events', value: '$count', icon: Icons.event),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Active', value: '$active', icon: Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 16),
                    _StatCard(title: 'Pending Review', value: '$pending', icon: Icons.hourglass_empty, color: Colors.orange),
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventFormScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Event'),
                ),
              ],
            ),
          ),
        ),
        StreamBuilder<List<EventModel>>(
          stream: adminService.getAllEventsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
            if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
            
            final events = snapshot.data!;
            if (events.isEmpty) return const SliverFillRemaining(child: Center(child: Text('No events found.')));

            return SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AdminEventCard(
                    event: events[index],
                    onStatusChange: (status, reason) => adminService.updateStatus(events[index].id, status, reason: reason),
                    onDelete: () => handleDelete(events[index]),
                    onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(event: events[index]))),
                  ),
                  childCount: events.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({required this.title, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? Colors.indigo).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? Colors.indigo),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final EventModel event;
  final Function(String, String?) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AdminEventCard({
    required this.event,
    required this.onStatusChange,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = event.status == 'active' 
        ? Colors.green 
        : event.status == 'under_review' 
            ? Colors.orange 
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(event.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${event.category} • ${event.location}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 2),
                Text('Posted by: ${event.postedByName ?? "Unknown"} • Price: ${event.price == "Free" ? "Free" : "₹${event.price}"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                if (event.paymentStatus != 'paid' && event.paymentStatus != 'free_period')
                  Text('Payment: ${event.paymentStatus}', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                initialValue: event.status,
                onSelected: (status) async {
                  if (status == 'rejected') {
                    final reason = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController();
                        return AlertDialog(
                          title: const Text('Reason for Rejection'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(hintText: 'e.g. Inappropriate content, Missing info'),
                            maxLines: 3,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Confirm Reject')),
                          ],
                        );
                      }
                    );
                    if (reason != null) {
                      onStatusChange(status, reason);
                    }
                  } else {
                    onStatusChange(status, null);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('Action', style: TextStyle(fontSize: 12)),
                      Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'active', child: Text('Approve / Active')),
                  const PopupMenuItem(value: 'under_review', child: Text('Set Pending')),
                  const PopupMenuItem(value: 'rejected', child: Text('Reject')),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit, tooltip: 'Edit'),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: onDelete, tooltip: 'Delete'),
            ],
          ),
        ],
      ),
    );
  }
}
