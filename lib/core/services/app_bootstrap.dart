import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import '../config/firebase_options_resolver.dart';
import 'notification_service.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: resolveFirebaseOptions(),
      );

      configureDependencies();
      await _configureAuthPersistence();
      await _configureAppCheck();
      await _configureCrashlytics();
      await NotificationService.instance.initialize();
    } catch (error, stackTrace) {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      } else {
        debugPrint('App bootstrap failed: $error');
      }
      rethrow;
    }
  }

  static Future<void> _configureCrashlytics() async {
    if (kIsWeb) {
      return;
    }

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> _configureAppCheck() async {
    if (kIsWeb) {
      final siteKey = const String.fromEnvironment('WEB_RECAPTCHA_SITE_KEY');
      if (siteKey.isEmpty) {
        return;
      }
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(siteKey),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  }

  static Future<void> _configureAuthPersistence() async {
    if (!kIsWeb) {
      return;
    }

    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
}
