/// One entry in a booking's `paymentHistory` array, returned (oldest first)
/// by the Point-to-Point / Airport / Hourly Charter booking-detail GET
/// endpoints alongside the booking itself.
///
/// More than one entry means the authorization hold behind the booking was
/// superseded at least once — either renewed ahead of Square's ~6-day
/// auto-expiry (so a trip booked far out doesn't get charged early) or
/// reconciled after a fare change. The backend doesn't distinguish the two
/// reasons, both just look like a superseded transaction here, so don't
/// read more into it than "something changed behind the scenes."
class PaymentHistoryEntry {
  const PaymentHistoryEntry({
    required this.status,
    required this.amountDollars,
    required this.createdAt,
  });

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.parse(v.toString());

    return PaymentHistoryEntry(
      status: json['status']?.toString() ?? '',
      amountDollars: asDouble(json['amountDollars']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  // One of: "AUTHORIZED" | "COMPLETED" | "CANCELED" | "REFUNDED".
  final String status;
  final double amountDollars;
  final DateTime? createdAt;
}
