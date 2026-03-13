import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.initialize();
  }
}
