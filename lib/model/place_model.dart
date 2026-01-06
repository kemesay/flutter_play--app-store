class Place {
  final String description;
  final String placeId;

  Place({required this.description, required this.placeId});

  Place.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        placeId = json['place_id'];

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'placeId': placeId,
    };
  }
}

class PlaceDetail {
  final String placeId;
  final String formattedAddress;
  final String? formattedPhoneNumber;
  final String? name;
  final double? rating;
  final String? vicinity;
  final String? website;
  final double lat;
  final double lng;
  final List<AddressComponent> addressComponents;
  final String? countryCode;
  final String? administrativeAreaShortName;

  PlaceDetail({
    required this.placeId,
    required this.formattedAddress,
    this.formattedPhoneNumber,
    this.name,
    this.rating,
    this.vicinity,
    this.website,
    required this.lat,
    required this.lng,
    List<AddressComponent>? addressComponents,
    String? countryCode,
    String? administrativeAreaShortName,
  })  : addressComponents = addressComponents ?? const [],
        countryCode =
            countryCode ?? _resolveCountryCode(addressComponents ?? const []),
        administrativeAreaShortName = administrativeAreaShortName ??
            _resolveAdministrativeArea(addressComponents ?? const []);

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final components =
        (json['address_components'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AddressComponent.fromJson)
            .toList();

    return PlaceDetail(
      placeId: json['place_id']?.toString() ?? '',
      formattedAddress: json['formatted_address']?.toString() ?? '',
      formattedPhoneNumber: json['formatted_phone_number']?.toString(),
      name: json['name']?.toString(),
      rating: _parseDouble(json['rating']),
      vicinity: json['vicinity']?.toString(),
      website: json['website']?.toString(),
      lat: _parseDouble(json['geometry']?['location']?['lat']) ?? 0,
      lng: _parseDouble(json['geometry']?['location']?['lng']) ?? 0,
      addressComponents: components,
      countryCode: _resolveCountryCode(components),
      administrativeAreaShortName: _resolveAdministrativeArea(components),
    );
  }

  PlaceDetail copyWith({
    String? placeId,
    String? formattedAddress,
    String? formattedPhoneNumber,
    String? name,
    double? rating,
    String? vicinity,
    String? website,
    double? lat,
    double? lng,
    List<AddressComponent>? addressComponents,
    String? countryCode,
    String? administrativeAreaShortName,
  }) {
    return PlaceDetail(
      placeId: placeId ?? this.placeId,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      vicinity: vicinity ?? this.vicinity,
      website: website ?? this.website,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      addressComponents: addressComponents ?? this.addressComponents,
      countryCode: countryCode ?? this.countryCode,
      administrativeAreaShortName:
          administrativeAreaShortName ?? this.administrativeAreaShortName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'formateedAddress': formattedAddress,
      'formateedPhoneNumber': formattedPhoneNumber,
      'name': name,
      'rating': rating,
      'vicinity': vicinity,
      'website': website,
      'lat': lat,
      'lng': lng,
      'countryCode': countryCode,
      'administrativeAreaShortName': administrativeAreaShortName,
      'addressComponents':
          addressComponents.map((component) => component.toMap()).toList(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _resolveCountryCode(List<AddressComponent> components) {
    for (final component in components) {
      if (component.types.contains('country')) {
        return component.shortName;
      }
    }
    return null;
  }

  static String? _resolveAdministrativeArea(List<AddressComponent> components) {
    for (final component in components) {
      if (component.types.contains('administrative_area_level_1')) {
        return component.shortName;
      }
    }
    return null;
  }
}

class AddressComponent {
  const AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  final String longName;
  final String shortName;
  final List<String> types;

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['types'] as List<dynamic>? ?? const [];
    return AddressComponent(
      longName: json['long_name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? '',
      types: rawTypes.map((type) => type.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'longName': longName,
      'shortName': shortName,
      'types': types,
    };
  }
}
