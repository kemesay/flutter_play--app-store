class SideDetourSettings {
  const SideDetourSettings({
    required this.isActive,
    required this.startFee,
  });

  final bool isActive;
  final double startFee;

  factory SideDetourSettings.fromJson(Map<String, dynamic> json) {
    return SideDetourSettings(
      isActive: json['isActive'] == true,
      startFee: (json['startFee'] as num?)?.toDouble() ?? 0,
    );
  }

  static const off = SideDetourSettings(isActive: false, startFee: 0);
}
