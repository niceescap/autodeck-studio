/// Configuration de l'app AutoDeck Studio.
///
/// L'URL du backend est injectée au build/run via --dart-define :
///
///   flutter run --dart-define=AUTODECK_API=https://44i.webredirect.org/autodeck
///
/// Si AUTODECK_API est absent ou vide → **mode démo** (stub local, zéro réseau).
class AppConfig {
  AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment("AUTODECK_API");

  /// true = aucun serveur joignable/configuré : tout est simulé localement.
  static bool get useStub => _apiBaseUrl.isEmpty;

  /// Base URL de l'API (sans / final). Ex. https://44i.webredirect.org/autodeck
  static String get apiBaseUrl => _apiBaseUrl;

  static const Duration httpTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration pollInterval = Duration(seconds: 2);
}
