class PopularPlaceModel {
  const PopularPlaceModel({
    required this.popularPlaceId,
    required this.title,
    required this.description,
    this.image,
  });

  final int popularPlaceId;
  final String title;
  final String description;
  final String? image;

  factory PopularPlaceModel.fromJson(Map<String, dynamic> json) {
    return PopularPlaceModel(
      popularPlaceId: _parseInt(json['popularPlaceId']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'popularPlaceId': popularPlaceId,
      'title': title,
      'description': description,
      'image': image,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

