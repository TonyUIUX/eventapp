import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/admin_providers.dart';
import '../services/firestore_admin_service.dart';
import '../models/app_config_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends ConsumerState<PricingManagementScreen> {
  final _feeController = TextEditingController();
  final _feeLabelController = TextEditingController();
  final _durationController = TextEditingController();
  final _freeReasonController = TextEditingController();
  final _promoTextController = TextEditingController();
  final _promoLinkController = TextEditingController();
  final _promoColorController = TextEditingController();
  final _promoCtaController = TextEditingController();
  final _maintenanceMsgController = TextEditingController();
  final _changeLogController = TextEditingController();
  
  bool _isFreePeriod = true;
  DateTime? _freePeriodEndsAt;
  bool _maintenanceMode = false;
  bool _showPromoBanner = false;
  bool _paymentEnabled = true;
  String _razorpayMode = 'test';
  bool _isSaving = false;

  @override
  void dispose() {
    _feeController.dispose();
    _feeLabelController.dispose();
    _durationController.dispose();
    _freeReasonController.dispose();
    _promoTextController.dispose();
    _promoLinkController.dispose();
    _promoColorController.dispose();
    _promoCtaController.dispose();
    _maintenanceMsgController.dispose();
    _changeLogController.dispose();
    super.dispose();
  }

  void _populateFields(AppConfigModel config) {
    _feeController.text = config.postingFee.toString();
    _feeLabelController.text = config.postingFeeLabel;
    _durationController.text = config.eventDurationDays.toString();
    _freeReasonController.text = config.freePeriodReason;
    _promoTextController.text = config.promoBannerText;
    _promoLinkController.text = config.promoBannerLink ?? '';
    _promoColorController.text = config.promoBannerColor;
    _promoCtaController.text = config.promoBannerCta;
    _maintenanceMsgController.text = config.maintenanceMessage;
    
    _isFreePeriod = config.isFreePeriod;
    _freePeriodEndsAt = config.freePeriodEndsAt;
    _maintenanceMode = config.maintenanceMode;
    _showPromoBanner = config.showPromoBanner;
    _paymentEnabled = config.paymentEnabled;
    _razorpayMode = config.razorpayMode;
  }

  Future<void> _handleSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Configuration Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('These changes will apply instantly to all app users with ZERO restart. Are you sure?'),
            const SizedBox(height: 16),
            Text('• Free Period: ${_isFreePeriod ? "ON" : "OFF"}'),
            Text('• Fee: ${_feeLabelController.text}'),
            Text('• Payments Enabled: ${_paymentEnabled ? "YES" : "NO"}'),
            Text('• Razorpay Mode: ${_razorpayMode.toUpperCase()}'),
            Text('• Maintenance Mode: ${_maintenanceMode ? "ON" : "OFF"}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apply Changes')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
      
      await FirestoreAdminService().updateAppConfig({
        'postingFee': int.tryParse(_feeController.text) ?? 0,
        'postingFeeLabel': _feeLabelController.text,
        'eventDurationDays': int.tryParse(_durationController.text) ?? 30,
        'isFreePeriod': _isFreePeriod,
        'freePeriodReason': _freeReasonController.text,
        'freePeriodEndsAt': _freePeriodEndsAt != null ? Timestamp.fromDate(_freePeriodEndsAt!) : null,
        'paymentEnabled': _paymentEnabled,
        'razorpayMode': _razorpayMode,
        'showPromoBanner': _showPromoBanner,
        'promoBannerText': _promoTextController.text,
        'promoBannerLink': _promoLinkController.text.isEmpty ? null : _promoLinkController.text,
        'promoBannerColor': _promoColorController.text,
        'promoBannerCta': _promoCtaController.text,
        'maintenanceMode': _maintenanceMode,
        'maintenanceMessage': _maintenanceMsgController.text,
      }, adminId, _changeLogController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration saved successfully.')));
      _changeLogController.clear();
      
      // Option to notify users
      _showNotifyOption();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showNotifyOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notify Users?'),
        content: const Text('Would you like to send a global broadcast about these updates?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openBroadcastWithTemplate();
            },
            child: const Text('Yes, Open Broadcast'),
          ),
        ],
      ),
    );
  }

  void _openBroadcastWithTemplate() {
    String template = 'Updates to KochiGo: ';
    if (_maintenanceMode) template += 'We are currently performing maintenance. ';
    if (!_isFreePeriod) {
      template += 'New posting fee is active: ${_feeLabelController.text}. ';
    } else {
      template += 'Enjoy a FREE posting period! ${_freeReasonController.text}. ';
    }
    
    final titleController = TextEditingController(text: 'Platform Update');
    final bodyController = TextEditingController(text: template);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Global Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
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
    final configAsync = ref.watch(adminConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Platform Config & Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving) const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator(strokeWidth: 2))),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save & Apply'),
            ),
          ),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          // Initialize controllers once
          if (_feeController.text.isEmpty && !_isSaving) _populateFields(config);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.maintenanceMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: const Text('⚠️ MAINTENANCE MODE IS ACTIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                else if (config.isFreePeriod)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                    child: const Text('🎉 FREE PERIOD IS ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                _SectionTitle('Posting & Pricing', icon: Icons.payments_outlined),
                _ConfigCard(
                  children: [
                    SwitchListTile(
                      title: const Text('Free Posting Period', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('If ON, users can post for free (skips payment).'),
                      value: _isFreePeriod,
                      onChanged: (v) => setState(() => _isFreePeriod = v),
                      activeThumbColor: Colors.green,
                    ),
                    const Divider(),
                    if (_isFreePeriod) ...[
                      _InputField(
                        label: 'Free Period Reason',
                        controller: _freeReasonController,
                        hint: 'e.g. Free for launch phase',
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('End Date (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                        subtitle: Text(_freePeriodEndsAt == null ? 'No end date set' : _freePeriodEndsAt!.toString()),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _freePeriodEndsAt ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _freePeriodEndsAt = date);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: 'Base Fee (Paise)',
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            hint: 'e.g. 4900 for ₹49',
                            enabled: !_isFreePeriod,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: 'Display Label',
                            controller: _feeLabelController,
                            hint: 'e.g. ₹49',
                            enabled: !_isFreePeriod,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: 'Duration (Days)',
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            suffixText: 'days',
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Razorpay Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _razorpayMode,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'test', child: Text('Test Mode')),
                                  DropdownMenuItem(value: 'live', child: Text('Live Mode')),
                                ],
                                onChanged: (v) async {
                                  if (v == 'live') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Enable Live Payments?'),
                                        content: const Text('Real transactions will be processed. Proceed with caution.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Go Live')),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) {
                                      setState(() {}); // refresh dropdown visually
                                      return;
                                    }
                                  }
                                  setState(() => _razorpayMode = v!);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Payment System Enabled', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('If OFF, payment step is hidden even if not free (emergency disable).'),
                      value: _paymentEnabled,
                      onChanged: (v) async {
                        if (!v) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Disable Payments?'),
                              content: const Text('This will hide the payment step for all users. Revenue will stop.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Disable')),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        setState(() => _paymentEnabled = v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                _SectionTitle('Promotional Banner', icon: Icons.campaign_outlined),
                _ConfigCard(
                  children: [
                    if (_showPromoBanner && _promoTextController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(int.tryParse(_promoColorController.text.replaceFirst('#', '0xFF')) ?? 0xFFFF5247),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_promoTextController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            if (_promoCtaController.text.isNotEmpty)
                              Text(_promoCtaController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                    ],
                    SwitchListTile(
                      title: const Text('Show Banner', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Show a globally dismissible banner to all users.'),
                      value: _showPromoBanner,
                      onChanged: (v) => setState(() => _showPromoBanner = v),
                    ),
                    const Divider(),
                    _InputField(
                      label: 'Banner Text',
                      controller: _promoTextController,
                      enabled: _showPromoBanner,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: 'CTA Text',
                            controller: _promoCtaController,
                            enabled: _showPromoBanner,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: 'Banner Color (Hex)',
                            controller: _promoColorController,
                            enabled: _showPromoBanner,
                            hint: '#FF5247',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: 'Target URL (Optional)',
                      controller: _promoLinkController,
                      enabled: _showPromoBanner,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                _SectionTitle('Maintenance Control', icon: Icons.construction_rounded, color: Colors.red),
                _ConfigCard(
                  borderColor: _maintenanceMode ? Colors.red : null,
                  children: [
                    SwitchListTile(
                      title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      subtitle: const Text('BLOCKS the entire app at root level. Use with extreme caution.'),
                      value: _maintenanceMode,
                      onChanged: (v) => setState(() => _maintenanceMode = v),
                      activeThumbColor: Colors.red,
                    ),
                    const Divider(),
                    _InputField(
                      label: 'Maintenance Message',
                      controller: _maintenanceMsgController,
                      maxLines: 2,
                      enabled: _maintenanceMode,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                _SectionTitle('Audit Log', icon: Icons.history_rounded),
                _InputField(
                  label: 'Internal Change Log (Why are you making this change?)',
                  controller: _changeLogController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Last updated by ${config.updatedBy} at ${config.updatedAt.toString()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  const _SectionTitle(this.title, {required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color ?? Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final List<Widget> children;
  final Color? borderColor;
  const _ConfigCard({required this.children, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.grey.shade200, width: borderColor != null ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffixText;
  final String? hint;
  final int maxLines;
  final bool enabled;

  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.suffixText,
    this.hint,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            filled: !enabled,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
