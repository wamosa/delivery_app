import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_paths.dart';
import '../../features/admin/domain/business_settings.dart';

class BusinessSettingsRepository {
  BusinessSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const BusinessSettings defaultSettings = BusinessSettings(
    businessName: 'Ayeyo Delivery',
    phone: '+254700111222',
    deliveryFee: 180,
    taxRate: 0,
    currency: 'KSh',
    pickupEnabled: true,
    orderingOpen: true,
    openingHoursNote: 'Breakfast 9:00-11:00, lunch 12:00-15:00',
    bannerMessage: 'Fresh meals for every session',
    activeOffer: 'Free juice on lunch combo orders',
  );

  Future<BusinessSettings> getBusinessSettings() async {
    final doc = await _firestore.doc(FirestorePaths.businessSettings).get();
    if (!doc.exists) {
      return defaultSettings;
    }

    return BusinessSettings.fromFirestore(doc);
  }

  Stream<BusinessSettings> watchBusinessSettings() {
    return _firestore.doc(FirestorePaths.businessSettings).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return defaultSettings;
      }

      return BusinessSettings.fromFirestore(doc);
    });
  }
}
