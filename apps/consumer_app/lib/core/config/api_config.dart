class ApiConfig {
  ApiConfig._();

  /// Set per flavor with `--dart-define-from-file=env/dev.json`.
  /// Defaults: Android emulator -> host machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}
