import 'dart:io';

import 'package:flutter/foundation.dart';

String resolvePaymentsBaseUrl() {
  const envUrl = String.fromEnvironment('PAYMENTS_BASE_URL', defaultValue: '');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:5000';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5000';
  }

  return 'http://localhost:5000';
}
