// App-wide constants for OmniForge AI
class AppConstants {
  AppConstants._();

  static const String appName = 'OmniForge AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'One App. Every AI.';

  // Storage keys
  static const String hiveBoxName = 'omniforge_db';
  static const String secureStorageKey = 'omniforge_secure';
  static const String encryptionSalt = 'omniforge_salt_v1';
  static const String prefsKey = 'omniforge_prefs';

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 16.0;
  static const double largeRadius = 24.0;
  static const double maxContentWidth = 720.0;

  // Network
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // AI
  static const int maxTokensDefault = 4096;
  static const double temperatureDefault = 0.7;
  static const int maxHistoryMessages = 50;
  static const int streamingChunkDelayMs = 30;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheValidity = Duration(hours: 24);
  static const int maxCacheEntries = 500;

  // Chat
  static const int maxAttachmentSize = 25 * 1024 * 1024; // 25 MB
  static const int maxAttachments = 5;
  static const int maxMessageLength = 32000;
}
