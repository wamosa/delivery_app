import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/payments_config.dart';

class PaymentsApiService {
  PaymentsApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> initiateStkPush({
    required double amount,
    required String phone,
    String? reference,
    String? description,
    String? orderId,
  }) async {
    final uri = Uri.parse('${resolvePaymentsBaseUrl()}/payments/initiate');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'phone': phone,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Payment initiation failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) {
      return body;
    }
    return Map<String, dynamic>.from(body as Map);
  }
}
