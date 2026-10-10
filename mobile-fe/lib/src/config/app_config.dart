class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const value = String.fromEnvironment('API_BASE_URL');
    if (value.trim().isEmpty) {
      throw const AppConfigurationException(
        'API_BASE_URL is missing. Run with '
        '--dart-define=API_BASE_URL=http://host:port',
      );
    }
    return AppConfig(apiBaseUrl: Uri.parse(value));
  }

  final Uri apiBaseUrl;
}

class AppConfigurationException implements Exception {
  const AppConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'App configuration error: $message';
}
