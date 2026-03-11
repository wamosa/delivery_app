import 'package:flutter/material.dart';

import 'app/ayeyo_app.dart';
import 'services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const AyeyoApp());
}
