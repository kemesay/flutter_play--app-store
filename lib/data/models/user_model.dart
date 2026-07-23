class UserModel {
  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.role,
    this.createdAt,
  });

  final int userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? role;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: _parseInt(json['userId']),
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      if (role != null) 'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

