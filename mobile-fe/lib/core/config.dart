class AppConfig {
  const AppConfig(this.apiBaseUrl);
  final String apiBaseUrl;

  static const fromEnvironment = AppConfig(
    String.fromEnvironment('API_BASE_URL'),
  );

  void validate() {
    assert(
      apiBaseUrl.isNotEmpty,
      'API_BASE_URL is required. Pass --dart-define=API_BASE_URL=https://…',
    );
  }
}
