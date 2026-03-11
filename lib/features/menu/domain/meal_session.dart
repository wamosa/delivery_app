import 'package:cloud_firestore/cloud_firestore.dart';

class MealSession {
  const MealSession({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.isActive,
  });

  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isActive;

  factory MealSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MealSession(
      id: doc.id,
      name: data['name'] as String? ?? '',
      startHour: data['startHour'] as int? ?? 0,
      startMinute: data['startMinute'] as int? ?? 0,
      endHour: data['endHour'] as int? ?? 0,
      endMinute: data['endMinute'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isActive': isActive,
    };
  }
}
