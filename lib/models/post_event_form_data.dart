import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostEventFormData {
  static const String draftKey = 'post_event_draft';

  String title = '';
  String description = '';
  String category = 'comedy';
  DateTime? date;
  String location = '';
  String? mapLink;
  String entryType = 'free'; // 'free' or 'paid'
  String price = 'Free';
  String? ticketLink;
  String? registrationLink;
  String organizer = '';
  String? contactPhone;
  String? contactInstagram;
  String? website;
  List<String> tags = [];
  
  // Local media for upload (not saved to draft for simplicity)
  List<Uint8List> images = [];

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date': date?.toIso8601String(),
      'location': location,
      'mapLink': mapLink,
      'price': entryType == 'free' ? 'Free' : price,
      'ticketLink': ticketLink,
      'registrationLink': registrationLink,
      'organizer': organizer,
      'contactPhone': contactPhone,
      'contactInstagram': contactInstagram,
      'website': website,
      'tags': tags,
    };
  }

  // --- Draft Management ---

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'title': title,
      'description': description,
      'category': category,
      'date': date?.toIso8601String(),
      'location': location,
      'mapLink': mapLink,
      'entryType': entryType,
      'price': price,
      'ticketLink': ticketLink,
      'registrationLink': registrationLink,
      'organizer': organizer,
      'contactPhone': contactPhone,
      'contactInstagram': contactInstagram,
      'website': website,
      'tags': tags,
    };
    await prefs.setString(draftKey, jsonEncode(data));
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(draftKey);
    if (jsonStr != null) {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      title = data['title'] ?? '';
      description = data['description'] ?? '';
      category = data['category'] ?? 'comedy';
      date = data['date'] != null ? DateTime.parse(data['date']) : null;
      location = data['location'] ?? '';
      mapLink = data['mapLink'];
      entryType = data['entryType'] ?? 'free';
      price = data['price'] ?? 'Free';
      ticketLink = data['ticketLink'];
      registrationLink = data['registrationLink'];
      organizer = data['organizer'] ?? '';
      contactPhone = data['contactPhone'];
      contactInstagram = data['contactInstagram'];
      website = data['website'];
      tags = List<String>.from(data['tags'] ?? []);
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(draftKey);
  }
}
