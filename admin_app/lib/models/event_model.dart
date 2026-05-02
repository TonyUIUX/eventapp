import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String mapLink;
  final String imageUrl;
  final List<String> imageUrls;
  final String organizer;
  final String? contactPhone;
  final String? contactInstagram;
  final String? website;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String price;
  final String? ticketLink;
  final String? registrationLink;
  final List<String> tags;
  
  // V3.0 User & Metrics Fields
  final int totalViews;
  final int totalShares;
  final String? postedBy;
  final String? postedByName;
  final String? postedByPhotoUrl;
  final bool isVerifiedOrg;
  final String tier;
  final String status; // active, under_review, rejected, expired
  final String paymentStatus; // free_period, pending, paid

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    required this.mapLink,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.organizer,
    this.contactPhone,
    this.contactInstagram,
    this.website,
    required this.isFeatured,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
    this.price = 'Free',
    this.ticketLink,
    this.registrationLink,
    this.tags = const [],
    this.totalViews = 0,
    this.totalShares = 0,
    this.postedBy,
    this.postedByName,
    this.postedByPhotoUrl,
    this.isVerifiedOrg = false,
    this.tier = 'standard',
    this.status = 'active',
    this.paymentStatus = 'paid',
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] ?? '',
      mapLink: data['mapLink'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'] as List)
          : (data['imageUrl'] != null ? [data['imageUrl'] as String] : []),
      organizer: data['organizer'] ?? '',
      contactPhone: data['contactPhone'] as String?,
      contactInstagram: data['contactInstagram'] as String?,
      website: data['website'] as String?,
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      price: data['price'] as String? ?? 'Free',
      ticketLink: data['ticketLink'] as String?,
      registrationLink: data['registrationLink'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : const [],
      totalViews: data['totalViews'] ?? data['viewCount'] ?? 0,
      totalShares: data['totalShares'] ?? 0,
      postedBy: data['postedBy'] ?? data['userId'] as String?,
      postedByName: data['postedByName'] as String?,
      postedByPhotoUrl: data['postedByPhotoUrl'] as String?,
      isVerifiedOrg: data['isVerifiedOrg'] ?? false,
      tier: data['tier'] ?? 'standard',
      status: data['status'] ?? 'active',
      paymentStatus: data['paymentStatus'] ?? 'paid',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'mapLink': mapLink,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'organizer': organizer,
      'contactPhone': contactPhone,
      'contactInstagram': contactInstagram,
      'website': website,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'price': price,
      'ticketLink': ticketLink,
      'registrationLink': registrationLink,
      'tags': tags,
      'totalViews': totalViews,
      'totalShares': totalShares,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'postedByPhotoUrl': postedByPhotoUrl,
      'isVerifiedOrg': isVerifiedOrg,
      'tier': tier,
      'status': status,
      'paymentStatus': paymentStatus,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'mapLink': mapLink,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'organizer': organizer,
      'contactPhone': contactPhone,
      'contactInstagram': contactInstagram,
      'website': website,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'price': price,
      'ticketLink': ticketLink,
      'registrationLink': registrationLink,
      'tags': tags,
      'totalViews': totalViews,
      'totalShares': totalShares,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'postedByPhotoUrl': postedByPhotoUrl,
      'isVerifiedOrg': isVerifiedOrg,
      'tier': tier,
      'status': status,
      'paymentStatus': paymentStatus,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> data) {
    return EventModel(
      id: data['id'] as String,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      date: DateTime.parse(data['date'] as String),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate'] as String) : null,
      location: data['location'] ?? '',
      mapLink: data['mapLink'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls'] as List) : [],
      organizer: data['organizer'] ?? '',
      contactPhone: data['contactPhone'] as String?,
      contactInstagram: data['contactInstagram'] as String?,
      website: data['website'] as String?,
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: DateTime.parse(data['createdAt'] as String),
      expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt'] as String) : null,
      price: data['price'] as String? ?? 'Free',
      ticketLink: data['ticketLink'] as String?,
      registrationLink: data['registrationLink'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : const [],
      totalViews: data['totalViews'] ?? 0,
      totalShares: data['totalShares'] ?? 0,
      postedBy: data['postedBy'] as String?,
      postedByName: data['postedByName'] as String?,
      postedByPhotoUrl: data['postedByPhotoUrl'] as String?,
      isVerifiedOrg: data['isVerifiedOrg'] ?? false,
      tier: data['tier'] ?? 'standard',
      status: data['status'] ?? 'active',
      paymentStatus: data['paymentStatus'] ?? 'paid',
    );
  }
}
