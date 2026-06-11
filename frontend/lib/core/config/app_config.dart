enum AppEnvironment { development, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final String socketUrl;
  final String appName;
  final bool enableLogging;
  final bool enableCrashlytics;
  final int connectionTimeout;
  final int receiveTimeout;

  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.appName,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.connectionTimeout,
    required this.receiveTimeout,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    _instance ??= AppConfig.development();
    return _instance!;
  }

  factory AppConfig.development() {
    _instance = const AppConfig._(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://10.0.2.2:8000/api/v1',
      socketUrl: 'http://10.0.2.2:8000',
      appName: 'HarfiDar Dev',
      enableLogging: true,
      enableCrashlytics: false,
      connectionTimeout: 30000,
      receiveTimeout: 30000,
    );
    return _instance!;
  }

  factory AppConfig.staging() {
    _instance = const AppConfig._(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://staging-api.harfidar.dz/api/v1',
      socketUrl: 'https://staging-api.harfidar.dz',
      appName: 'HarfiDar Staging',
      enableLogging: true,
      enableCrashlytics: true,
      connectionTimeout: 30000,
      receiveTimeout: 30000,
    );
    return _instance!;
  }

  factory AppConfig.production() {
    _instance = const AppConfig._(
      environment: AppEnvironment.production,
      apiBaseUrl: 'https://api.harfidar.dz/api/v1',
      socketUrl: 'https://api.harfidar.dz',
      appName: 'حرفي دار',
      enableLogging: false,
      enableCrashlytics: true,
      connectionTimeout: 30000,
      receiveTimeout: 30000,
    );
    return _instance!;
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;
}
