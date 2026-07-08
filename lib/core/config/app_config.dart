enum Environment { development, beta, release }

/// Application configurations and compilation env parameters.
class AppConfig {
  final Environment environment;
  final String apiVersion;
  final String buildSuffix;
  final String versionString;

  const AppConfig({
    required this.environment,
    required this.apiVersion,
    required this.buildSuffix,
    required this.versionString,
  });

  bool get isDevelopment => environment == Environment.development;
  bool get isBeta => environment == Environment.beta;
  bool get isRelease => environment == Environment.release;
}
