import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import '../../firebase_options.dart';
import '../../firebase_options_dev.dart';
import '../../firebase_options_staging.dart';
import 'app_env.dart';

FirebaseOptions resolveFirebaseOptions() {
  final env = currentAppEnv();
  switch (env) {
    case AppEnv.dev:
      return DevFirebaseOptions.currentPlatform;
    case AppEnv.staging:
      return StagingFirebaseOptions.currentPlatform;
    case AppEnv.prod:
      return DefaultFirebaseOptions.currentPlatform;
  }
}
