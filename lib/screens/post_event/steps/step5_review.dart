import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/post_event_form_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../providers/app_config_provider.dart';
import '../../../../core/widgets/gradient_button.dart';

class Step5Review extends ConsumerWidget {
  final PostEventFormData formData;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  const Step5Review({
    super.key,
    required this.formData,
    required this.onConfirm,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EVENT PREVIEW', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 12),
          
          // Custom Preview Card mimicking EventCard style
          _PreviewCard(formData: formData),
          
          const SizedBox(height: 32),
          
          Text('SUMMARY', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 16),
          _SummaryTile(icon: Icons.location_on_rounded, label: 'Venue', value: formData.location),
          _SummaryTile(icon: Icons.local_activity_rounded, label: 'Type', value: formData.entryType == 'free' ? 'Free Entry' : 'Paid / Tickets'),
          _SummaryTile(icon: Icons.sell_rounded, label: 'Price', value: formData.entryType == 'free' ? 'Free' : formData.price),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: AppColors.glassBorder),
          ),
          
          configAsync.when(
            data: (config) {
              final fee = config.postingFee / 100;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PUBLISHING FEE', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
                  const SizedBox(height: 12),
                  
                  // Fee Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: config.requiresPayment ? AppColors.glassBorder : AppColors.brandCoral.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(config.requiresPayment ? 'Standard Listing' : 'Promotional Offer', style: AppTextStyles.label.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              config.requiresPayment ? 'Secure payment via Razorpay' : 'List your event for free',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (config.requiresPayment)
                          Text('₹${fee.toStringAsFixed(0)}', style: AppTextStyles.heading1.copyWith(color: Colors.white))
                        else
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: const Text('FREE', style: AppTextStyles.heading1),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Terms Bullets
                  _TermBullet(text: 'Your event will be live for ${config.eventDurationDays} days after approval.'),
                  const _TermBullet(text: 'Moderation takes up to 24 hours.'),
                  if (!config.requiresPayment)
                    _TermBullet(text: config.freePeriodReason, isItalic: true),
                  
                  const SizedBox(height: 48),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: config.requiresPayment ? 'Pay & Submit' : 'Submit for Review',
                      isLoading: isSubmitting,
                      height: 56,
                      onTap: isSubmitting ? () {} : onConfirm,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandCoral)),
            error: (_, __) => Text('Error loading platform config', style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
          
          const SizedBox(height: 48), // Bottom padding
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PostEventFormData formData;
  const _PreviewCard({required this.formData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              image: formData.images.isNotEmpty
                  ? DecorationImage(image: MemoryImage(formData.images[0]), fit: BoxFit.cover)
                  : null,
              color: formData.images.isEmpty ? AppColors.glassSurface : null,
            ),
            child: formData.images.isEmpty
                ? Center(child: Text('No Cover Photo', style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)))
                : null,
          ),
          
          // Content Area
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formData.date != null ? DateFormat('MMM dd, yyyy').format(formData.date!) : 'Date Not Set',
                      style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formData.entryType == 'free' ? 'FREE' : formData.price.isNotEmpty ? formData.price : 'PAID',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formData.title.isEmpty ? 'Event Title' : formData.title,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formData.location.isEmpty ? 'Venue Location' : formData.location,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, color: AppColors.brandCoral, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Not set' : value, style: AppTextStyles.label.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermBullet extends StatelessWidget {
  final String text;
  final bool isItalic;
  
  const _TermBullet({required this.text, this.isItalic = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: AppColors.brandCoral, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
