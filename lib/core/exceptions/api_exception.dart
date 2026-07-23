class ApiException implements Exception {
  const ApiException({this.statusCode, required this.message, this.details});

  final int? statusCode;
  final String message;
  final Object? details;

  // Deliberately just the message: this is what every screen shows via
  // `e.toString()` or string interpolation, so it must read exactly like
  // the clean, user-safe text the backend already sanitized — not a
  // debug-style "ApiException(statusCode: ..., message: ...)" wrapper.
  @override
  String toString() => message;
}
