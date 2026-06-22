// OmniForge AI - Main Entry Point
// Production-grade AI Super App for Android
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app.dart';
import 'injection/injection.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized BEFORE any other async work.
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration first so SENTRY_DSN is available.
  // Guarded the same way Firebase.initializeApp() is below: .env is
  // gitignored (see .env.example for the template), so a fresh checkout
  // or a CI runner that doesn't provision it must still boot — provider
  // base URLs/keys are also configurable at runtime via Settings > API
  // Keys, so an empty environment is a degraded-but-functional state,
  // not a crash.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    AppLogger.w(
      '.env not found or unreadable — continuing with defaults. '
      'Copy .env.example to .env to configure provider URLs/keys, or set '
      'them in-app via Settings > API Keys. Error: $e',
    );
    dotenv.testLoad(fileInput: '');
  }

  final sentryDsn = dotenv.maybeGet('SENTRY_DSN') ?? '';

  // SentryFlutter.init wraps runApp (via appRunner) in a guarded zone
  // that captures uncaught errors and reports them to Sentry. The DSN
  // being empty just disables Sentry; the app still runs.
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
      options.sendDefaultPii = false;
    },
    appRunner: () async {
      // Lock orientation to portrait for mobile-first experience.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Status bar transparency for immersive UI.
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
        ),
      );

      // Initialize Firebase. This requires a real `google-services.json`
      // (from your own Firebase console) dropped into android/app/ — the
      // Gradle build only applies the Google Services plugin when that
      // file is present (see android/app/build.gradle.kts), so a fresh
      // checkout without one still builds and runs fine, just without
      // Crashlytics. Guarded here too so a missing/misconfigured project
      // degrades to "no crash reporting" instead of crashing on every
      // single launch before the UI ever appears.
      var firebaseReady = false;
      try {
        await Firebase.initializeApp();
        firebaseReady = true;
      } catch (e) {
        AppLogger.w(
          'Firebase.initializeApp() failed — continuing without Crashlytics. '
          'Add android/app/google-services.json from your Firebase console '
          'to enable it. Error: $e',
        );
      }

      if (firebaseReady) {
        // Route Flutter framework errors and uncaught Dart errors to
        // Crashlytics. Wrapped in its own try/catch so a Crashlytics-side
        // failure (e.g. collection disabled) can't take the app down.
        try {
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stack,
              fatal: true,
            );
            return true;
          };
        } catch (e) {
          AppLogger.w('Crashlytics wiring failed: $e');
        }
      }

      // Initialize HydratedBloc storage for state persistence.
      final storage = await HydratedStorage.build(
        storageDirectory: await getApplicationDocumentsDirectory(),
      );
      HydratedBloc.storage = storage;

      // Configure Dependency Injection (resolves all async singletons).
      await configureDependencies();

      runApp(const OmniForgeApp());
    },
  );
}
