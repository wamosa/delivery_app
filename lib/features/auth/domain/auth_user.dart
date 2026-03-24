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
  final normalized = value?.trim().toLowerCase();
  switch (normalized) {
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

  factory AuthUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    AuthRole? roleOverride,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    String? asString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    AuthRole parseRole() {
      final roleValue = data['role'];
      if (roleValue is String || roleValue == null) {
        return authRoleFromKey(roleValue as String?);
      }
      if (roleValue is bool) {
        return roleValue ? AuthRole.admin : AuthRole.customer;
      }
      if (roleValue is num) {
        return roleValue > 0 ? AuthRole.admin : AuthRole.customer;
      }
      final legacyIsAdmin = data['isAdmin'];
      if (legacyIsAdmin is bool) {
        return legacyIsAdmin ? AuthRole.admin : AuthRole.customer;
      }
      return AuthRole.customer;
    }
    return AuthUser(
      id: doc.id,
      name: asString(data['name']) ?? '',
      phone: asString(data['phone']) ?? '',
      email: asString(data['email']) ?? '',
      role: roleOverride ?? parseRole(),
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
