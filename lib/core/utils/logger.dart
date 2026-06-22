// Logger utility using the logger package
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _instance = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void d(dynamic message) => _instance.d(message);
  static void i(dynamic message) => _instance.i(message);
  static void w(dynamic message) => _instance.w(message);
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) =>
      _instance.e(message, error: error, stackTrace: stackTrace);
  static void wtf(dynamic message) => _instance.f(message);
}
