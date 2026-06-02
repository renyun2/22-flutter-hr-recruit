class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:3009',
  );
}
