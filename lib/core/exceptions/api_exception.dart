class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    required this.message,
    this.details,
    this.isTimeout = false,
  });

  final int? statusCode;
  final String message;
  final Object? details;

  /// True when this came from a client-side timeout rather than a server
  /// response. A timed-out request may still be processed by the server —
  /// unlike an HTTP error status, it does NOT mean the operation was
  /// rejected, so callers that create/modify data should treat the outcome
  /// as unknown rather than assuming it failed.
  final bool isTimeout;

  // Deliberately just the message: this is what every screen shows via
  // `e.toString()` or string interpolation, so it must read exactly like
  // the clean, user-safe text the backend already sanitized — not a
  // debug-style "ApiException(statusCode: ..., message: ...)" wrapper.
  @override
  String toString() => message;
}
