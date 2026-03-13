import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthRole {
  admin,
  counter,
  rider,
  customer,
}

extension AuthRoleX on AuthRole {
  String get key {
    switch (this) {
      case AuthRole.admin:
        return 'admin';
      case AuthRole.counter:
        return 'counter';
      case AuthRole.rider:
        return 'rider';
      case AuthRole.customer:
        return 'customer';
    }
  }

  String get label {
    switch (this) {
      case AuthRole.admin:
        return 'Admin';
      case AuthRole.counter:
        return 'Counter';
      case AuthRole.rider:
        return 'Rider';
      case AuthRole.customer:
        return 'Customer';
    }
  }
}

AuthRole authRoleFromKey(String? value) {
  switch (value) {
    case 'admin':
      return AuthRole.admin;
    case 'counter':
      return AuthRole.counter;
    case 'rider':
      return AuthRole.rider;
    case 'customer':
    default:
      return AuthRole.customer;
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final AuthRole role;

  factory AuthUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AuthUser(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: authRoleFromKey(data['role'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.key,
    };
  }
}
