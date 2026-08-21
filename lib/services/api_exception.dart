/// Typisierte API-Fehler mit ehrlicher Ursache statt generischem
/// "API Fehler". [userMessage] ist kurz und nutzerfreundlich (Schwedisch),
/// [technicalDetail] enthält die echten Infos fürs Debugging.
class ApiException implements Exception {
  final ApiExceptionKind kind;
  final String userMessage;
  final String? technicalDetail;
  final int? statusCode;

  const ApiException({
    required this.kind,
    required this.userMessage,
    this.technicalDetail,
    this.statusCode,
  });

  factory ApiException.missingKey(String keyName) => ApiException(
        kind: ApiExceptionKind.missingKey,
        userMessage: 'API-nyckel $keyName saknas. Lägg till den i Settings eller .env.',
      );

  factory ApiException.tls(Object error) => ApiException(
        kind: ApiExceptionKind.tls,
        userMessage: 'Säker anslutning misslyckades. Använd proxy-läget (BFF) i inställningarna.',
        technicalDetail: 'TLS handshake failed: $error',
      );

  factory ApiException.http(int statusCode, String endpoint, {String? bodySnippet}) {
    final reason = switch (statusCode) {
      401 || 403 => 'API-nyckeln är ogiltig eller saknar behörighet',
      404 => 'Resursen hittades inte',
      429 => 'För många förfrågningar – försök igen om en stund',
      >= 500 => 'Upstream-tjänsten har ett internt fel',
      _ => 'HTTP-fel',
    };
    return ApiException(
      kind: ApiExceptionKind.http,
      statusCode: statusCode,
      userMessage: '$reason (HTTP $statusCode från $endpoint).',
      technicalDetail: bodySnippet,
    );
  }

  factory ApiException.network(Object error) => ApiException(
        kind: ApiExceptionKind.network,
        userMessage: 'Nätverksfel – kontrollera internetanslutningen.',
        technicalDetail: '$error',
      );

  /// BFF-Server (Proxy-Modus) ist nicht erreichbar – mit konkretem Hinweis
  /// auf die konfigurierte URL, statt eines generischen Timeout-Fehlers.
  factory ApiException.bffOffline(String baseUrl, {Object? cause}) => ApiException(
        kind: ApiExceptionKind.bffOffline,
        userMessage: 'BFF-servern är inte nåbar på $baseUrl – kör du Go-backend?',
        technicalDetail: '$cause',
      );

  @override
  String toString() {
    final detail = technicalDetail == null ? '' : ' ($technicalDetail)';
    return 'ApiException[${kind.name}]: $userMessage$detail';
  }
}

enum ApiExceptionKind {
  missingKey,
  tls,
  network,
  http,
  noData,
  bffOffline,
}
