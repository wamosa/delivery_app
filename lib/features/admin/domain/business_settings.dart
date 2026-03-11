import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessSettings {
  const BusinessSettings({
    required this.businessName,
    required this.phone,
    required this.deliveryFee,
    required this.taxRate,
    required this.currency,
    required this.pickupEnabled,
    required this.orderingOpen,
    required this.openingHoursNote,
    required this.bannerMessage,
    required this.activeOffer,
  });

  final String businessName;
  final String phone;
  final double deliveryFee;
  final double taxRate;
  final String currency;
  final bool pickupEnabled;
  final bool orderingOpen;
  final String openingHoursNote;
  final String bannerMessage;
  final String activeOffer;

  factory BusinessSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return BusinessSettings(
      businessName: data['businessName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'KES',
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0,
      pickupEnabled: data['pickupEnabled'] as bool? ?? true,
      orderingOpen: data['orderingOpen'] as bool? ?? true,
      openingHoursNote: data['openingHoursNote'] as String? ?? '',
      bannerMessage: data['bannerMessage'] as String? ?? '',
      activeOffer: data['activeOffer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'phone': phone,
      'deliveryFee': deliveryFee,
      'taxRate': taxRate,
      'currency': currency,
      'pickupEnabled': pickupEnabled,
      'orderingOpen': orderingOpen,
      'openingHoursNote': openingHoursNote,
      'bannerMessage': bannerMessage,
      'activeOffer': activeOffer,
    };
  }
}
