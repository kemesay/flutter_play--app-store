import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../config/app_config.dart';

class PaymentTransactionUpdatedEvent {
  const PaymentTransactionUpdatedEvent({
    required this.bookingType,
    required this.bookingId,
    required this.status,
    this.confirmationNumber,
    this.squarePaymentId,
    this.amountCents,
    this.currency,
    this.updatedAt,
  });

  final String bookingType;
  final int bookingId;
  final String status;
  final String? confirmationNumber;
  final String? squarePaymentId;
  final int? amountCents;
  final String? currency;
  final String? updatedAt;

  factory PaymentTransactionUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionUpdatedEvent(
      bookingType: (json['bookingType'] ?? '').toString(),
      bookingId: int.tryParse((json['bookingId'] ?? '').toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
      confirmationNumber: json['confirmationNumber']?.toString(),
      squarePaymentId: json['squarePaymentId']?.toString(),
      amountCents: json['amountCents'] is num
          ? (json['amountCents'] as num).toInt()
          : int.tryParse('${json['amountCents']}'),
      currency: json['currency']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class SocketClientService {
  SocketClientService._();
  static final SocketClientService instance = SocketClientService._();

  sio.Socket? _socket;
  final _paymentTxController =
      StreamController<PaymentTransactionUpdatedEvent>.broadcast();

  Stream<PaymentTransactionUpdatedEvent> get paymentTransactionUpdated =>
      _paymentTxController.stream;

  /// Socket.IO server origin (API host without `/api/v1`).
  ///
  /// Always includes an explicit port, even the scheme's default one. This
  /// looks redundant for plain http/https, but it matters here: the
  /// socket_io_client package converts this into a `ws`/`wss` URL, and
  /// Dart's own `Uri` class (unlike for http/https) has no built-in notion
  /// of a default port for `ws`/`wss` — an omitted port resolves to 0, not
  /// 443, producing a broken `wss://host:0/...` connection URL further down
  /// the chain. Writing the port explicitly here sidesteps that gap
  /// entirely, since an explicit port is parsed literally either way.
  String _socketOrigin() {
    final api = Uri.parse(AppConfig.apiBaseUrl);
    final port = api.hasPort ? api.port : (api.scheme == 'https' ? 443 : 80);
    return '${api.scheme}://${api.host}:$port';
  }

  /// Web uses polling + upgrade; dart:io only implements websocket transport.
  List<String> _socketTransports() {
    if (kIsWeb) {
      return const ['polling', 'websocket'];
    }
    return const ['websocket'];
  }

  void ensureConnected() {
    if (_socket != null) return;

    final url = _socketOrigin();
    const socketPath = '/api/v1/socket.io';
    final socket = sio.io(
      url,
      <String, dynamic>{
        'path': socketPath,
        'transports': _socketTransports(),
        'autoConnect': true,
        'reconnection': true,
        // Realtime payment updates are strictly best-effort (booking flows
        // never depend on this connection succeeding). Cap retries instead
        // of reconnecting forever, so a server/proxy-side outage doesn't
        // burn battery and network indefinitely — it just gives up
        // gracefully after a reasonable number of attempts.
        'reconnectionAttempts': 10,
      },
    );

    socket.on('connect_error', (data) {
      if (kDebugMode) debugPrint('socket connect_error: $data');
    });
    socket.on('error', (data) {
      if (kDebugMode) debugPrint('socket error: $data');
    });
    socket.on('payment.transaction.updated', (data) {
      if (data is Map) {
        final map = data.map((k, v) => MapEntry(k.toString(), v));
        _paymentTxController.add(PaymentTransactionUpdatedEvent.fromJson(map));
      }
    });

    _socket = socket;
  }

  void joinBookingRoom({required String roomToken}) {
    ensureConnected();
    _socket?.emit('join', {'token': roomToken});
  }

  void leaveBookingRoom({required String roomToken}) {
    _socket?.emit('leave', {'token': roomToken});
  }

  /// Disconnects the current session's socket, e.g. on logout, without
  /// permanently closing [paymentTransactionUpdated] — unlike [dispose],
  /// this can be followed by [ensureConnected] again on the next login,
  /// which will open a brand-new connection rather than silently reusing a
  /// stale one still tied to the previous user's room subscriptions.
  void reset() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _paymentTxController.close();
  }
}
