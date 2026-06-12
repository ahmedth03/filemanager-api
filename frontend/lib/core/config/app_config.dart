/// Application environment enumeration.
enum AppEnvironment { development, staging, production }

/// Holds all environment-specific configuration values.
///
/// Usage:
/// ```dart
/// // In main.dart – pick the right config at compile time:
/// AppConfig.initialize(AppEnvironment.development);
///
/// // Anywhere else:
/// final baseUrl = AppConfig.instance.apiBaseUrl;
/// ```
class AppConfig {
  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.appName,
    required this.mapsApiKey,
    required this.sentryDsn,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.connectTimeoutSeconds,
    required this.receiveTimeoutSeconds,
    required this.maxRetries,
  });

  // ── Singleton ─────────────────────────────────────────────────────────────
  static AppConfig? _instance;

  static AppConfig get instance {
    _instance ??= AppConfig._fromEnvironment(AppEnvironment.development);
    return _instance!;
  }

  static bool _initialized = false;

  // ── Fields ────────────────────────────────────────────────────────────────
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String socketUrl;
  final String appName;
  final String mapsApiKey;
  final String sentryDsn;
  final bool enableLogging;
  final bool enableCrashlytics;
  final int connectTimeoutSeconds;
  final int receiveTimeoutSeconds;
  final int maxRetries;

  // ── Computed helpers ──────────────────────────────────────────────────────
  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  // ── Factory initializer ───────────────────────────────────────────────────
  static void initialize([AppEnvironment env = AppEnvironment.development]) {
    if (_initialized) return;
    _initialized = true;
    _instance = AppConfig._fromEnvironment(env);
  }

  factory AppConfig.development() => AppConfig._fromEnvironment(AppEnvironment.development);
  factory AppConfig.staging() => AppConfig._fromEnvironment(AppEnvironment.staging);
  factory AppConfig.production() => AppConfig._fromEnvironment(AppEnvironment.production);

  static AppConfig _fromEnvironment(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return AppConfig._(
          environment: env,
          apiBaseUrl: 'http://10.0.2.2:8080/api/v1',
          socketUrl: 'ws://10.0.2.2:8080',
          appName: 'HarfiDar Dev',
          mapsApiKey: 'DEV_MAPS_KEY',
          sentryDsn: '',
          enableLogging: true,
          enableCrashlytics: false,
          connectTimeoutSeconds: 30,
          receiveTimeoutSeconds: 30,
          maxRetries: 1,
        );

      case AppEnvironment.staging:
        return AppConfig._(
          environment: env,
          apiBaseUrl: 'https://staging-api.harfidar.dz/api/v1',
          socketUrl: 'wss://staging-api.harfidar.dz',
          appName: 'HarfiDar Staging',
          mapsApiKey: 'STAGING_MAPS_KEY',
          sentryDsn: 'https://staging@sentry.io/harfidar',
          enableLogging: true,
          enableCrashlytics: true,
          connectTimeoutSeconds: 30,
          receiveTimeoutSeconds: 30,
          maxRetries: 2,
        );

      case AppEnvironment.production:
        return AppConfig._(
          environment: env,
          apiBaseUrl: 'https://api.harfidar.dz/api/v1',
          socketUrl: 'wss://api.harfidar.dz',
          appName: 'حرفي دار',
          mapsApiKey: 'PROD_MAPS_KEY',
          sentryDsn: 'https://prod@sentry.io/harfidar',
          enableLogging: false,
          enableCrashlytics: true,
          connectTimeoutSeconds: 20,
          receiveTimeoutSeconds: 20,
          maxRetries: 3,
        );
    }
  }

  @override
  String toString() => 'AppConfig(env: $environment, baseUrl: $apiBaseUrl)';
}
