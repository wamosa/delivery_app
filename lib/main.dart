import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/ayeyo_app.dart';
import 'core/services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppStartup());
}

class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AppBootstrap.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _StartupStatusScreen(
              title: 'Starting Ayeyo',
              message: 'please wait while we prepare everything for you...',
            ),
          );
        }

        if (snapshot.hasError) {
          final errorDetails = snapshot.error?.toString() ?? 'Unknown error';
          final message = kDebugMode
              ? 'Startup failed: $errorDetails'
              : 'We could not start the app. Please check your connection and try again.';
          return MaterialApp(
            home: _StartupStatusScreen(
              title: 'Startup failed',
              message: message,
            ),
          );
        }

        return const AyeyoApp();
      },
    );
  }
}

class _StartupStatusScreen extends StatelessWidget {
  const _StartupStatusScreen({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
