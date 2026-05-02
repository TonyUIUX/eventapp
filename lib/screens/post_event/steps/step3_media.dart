import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../models/post_event_form_data.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tap_scale.dart';

class Step3Media extends StatelessWidget {
  final PostEventFormData formData;
  final VoidCallback onUpdate;
  
  const Step3Media({super.key, required this.formData, required this.onUpdate});

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Event Photo',
            toolbarColor: AppColors.backgroundCard,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
            backgroundColor: AppColors.backgroundBase,
            activeControlsWidgetColor: AppColors.brandCoral,
          ),
          IOSUiSettings(
            title: 'Crop Event Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        formData.images.add(bytes);
        onUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COVER PHOTO (REQUIRED)', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
          const SizedBox(height: 8),
          
          if (formData.images.isEmpty)
            TapScale(
              onTap: _pickImage,
              child: CustomPaint(
                painter: _DashedBorderPainter(color: AppColors.glassBorder),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * (9 / 16),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundCard.withValues(alpha: 0.5),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.brandCoral, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text('Add Cover Photo', style: AppTextStyles.label.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('16:9 ratio recommended', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            )
          else
            TapScale(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * (9 / 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.glassBorder),
                  image: DecorationImage(
                    image: MemoryImage(formData.images[0]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text('Change Cover', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GALLERY PHOTOS', style: AppTextStyles.caption.copyWith(color: AppColors.brandCoral)),
              Text('${formData.images.length > 1 ? formData.images.length - 1 : 0} / 4', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (formData.images.length > 1)
                ...List.generate(formData.images.length - 1, (index) {
                  final actualIndex = index + 1;
                  return _GalleryThumbnail(
                    imageBytes: formData.images[actualIndex],
                    onRemove: () {
                      formData.images.removeAt(actualIndex);
                      onUpdate();
                    },
                  );
                }),
              if (formData.images.isNotEmpty && formData.images.length < 5)
                TapScale(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 28),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  final dynamic imageBytes;
  final VoidCallback onRemove;

  const _GalleryThumbnail({required this.imageBytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
            image: DecorationImage(
              image: MemoryImage(imageBytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: TapScale(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(AppRadius.lg),
    );
    path.addRRect(rrect);

    // Simple dash effect
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    
    // Convert path to dashed
    Path dashedPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < measurePath.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dashedPath.addPath(
            measurePath.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
