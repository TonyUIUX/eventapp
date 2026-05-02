import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class AppUrlUtils {
  static Future<void> openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF161616), // AppColors.backgroundCard equivalent since not imported
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x33FFFFFF))), // AppColors.glassBorder equivalent
          ),
        );
      }
    }
  }

  static Future<void> callPhone(String phone, BuildContext context) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openInstagram(String handle, BuildContext context) async {
    final username = handle.replaceFirst('@', '');
    final uri = Uri.parse('https://instagram.com/$username');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> addToGoogleCalendar({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required BuildContext context,
  }) async {
    // Format: 20231231T180000Z
    String formatGCalDate(DateTime dt) {
      return "${dt.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z";
    }

    final startStr = formatGCalDate(startDate);
    final endStr = formatGCalDate(startDate.add(const Duration(hours: 2))); // Assume 2 hour duration
    
    const baseUrl = "https://calendar.google.com/calendar/render?action=TEMPLATE";
    final url = "$baseUrl&text=${Uri.encodeComponent(title)}&dates=$startStr/$endStr&details=${Uri.encodeComponent(description)}&location=${Uri.encodeComponent(location)}";
    
    await openUrl(url, context);
  }
}
