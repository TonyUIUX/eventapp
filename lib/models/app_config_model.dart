import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigModel {
  final int postingFee;
  final String postingFeeLabel;
  final int eventDurationDays;
  final bool isFreePeriod;
  final String freePeriodReason;
  final DateTime? freePeriodEndsAt;
  final bool paymentEnabled;
  final String razorpayMode;
  final bool showPromoBanner;
  final String promoBannerText;
  final String? promoBannerLink;
  final String promoBannerColor;
  final String promoBannerCta;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final DateTime updatedAt;
  final String updatedBy;
  final String? changeLog;

  AppConfigModel({
    required this.postingFee,
    required this.postingFeeLabel,
    required this.eventDurationDays,
    required this.isFreePeriod,
    required this.freePeriodReason,
    this.freePeriodEndsAt,
    required this.paymentEnabled,
    required this.razorpayMode,
    required this.showPromoBanner,
    required this.promoBannerText,
    this.promoBannerLink,
    required this.promoBannerColor,
    required this.promoBannerCta,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.updatedAt,
    required this.updatedBy,
    this.changeLog,
  });

  bool get requiresPayment => !isFreePeriod && paymentEnabled && postingFee > 0;
  
  bool get freePeriodEndingSoon {
    if (freePeriodEndsAt == null) return false;
    return freePeriodEndsAt!.difference(DateTime.now()).inDays <= 3;
  }

  factory AppConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppConfigModel(
      postingFee: data['postingFee'] ?? 0,
      postingFeeLabel: data['postingFeeLabel'] ?? '₹0',
      eventDurationDays: data['eventDurationDays'] ?? 30,
      isFreePeriod: data['isFreePeriod'] ?? true,
      freePeriodReason: data['freePeriodReason'] ?? 'Free for a limited time',
      freePeriodEndsAt: (data['freePeriodEndsAt'] as Timestamp?)?.toDate(),
      paymentEnabled: data['paymentEnabled'] ?? false,
      razorpayMode: data['razorpayMode'] ?? 'test',
      showPromoBanner: data['showPromoBanner'] ?? false,
      promoBannerText: data['promoBannerText'] ?? '',
      promoBannerLink: data['promoBannerLink'],
      promoBannerColor: data['promoBannerColor'] ?? '#FF5247',
      promoBannerCta: data['promoBannerCta'] ?? 'Learn More',
      maintenanceMode: data['maintenanceMode'] ?? false,
      maintenanceMessage: data['maintenanceMessage'] ?? 'We are currently under maintenance. Please check back later.',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] ?? 'system',
      changeLog: data['changeLog'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postingFee': postingFee,
      'postingFeeLabel': postingFeeLabel,
      'eventDurationDays': eventDurationDays,
      'isFreePeriod': isFreePeriod,
      'freePeriodReason': freePeriodReason,
      'freePeriodEndsAt': freePeriodEndsAt != null ? Timestamp.fromDate(freePeriodEndsAt!) : null,
      'paymentEnabled': paymentEnabled,
      'razorpayMode': razorpayMode,
      'showPromoBanner': showPromoBanner,
      'promoBannerText': promoBannerText,
      'promoBannerLink': promoBannerLink,
      'promoBannerColor': promoBannerColor,
      'promoBannerCta': promoBannerCta,
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'changeLog': changeLog,
    };
  }

  factory AppConfigModel.initial() {
    return AppConfigModel(
      postingFee: 0,
      postingFeeLabel: '₹0',
      eventDurationDays: 30,
      isFreePeriod: true,
      freePeriodReason: 'Free for launch phase',
      freePeriodEndsAt: null,
      paymentEnabled: false,
      razorpayMode: 'test',
      showPromoBanner: false,
      promoBannerText: '',
      promoBannerLink: null,
      promoBannerColor: '#FF5247',
      promoBannerCta: 'Learn More',
      maintenanceMode: false,
      maintenanceMessage: 'KochiGo is upgrading to serve you better!',
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }
}
