import 'package:flutter/foundation.dart';

import '../data/models/additional_stop_model.dart';
import '../data/models/airport_model.dart';
import '../data/models/airport_pickup_preference_model.dart';
import '../data/models/car_model.dart';
import '../data/models/extra_option_model.dart';
import '../data/models/gratuity_model.dart';
import '../data/models/popular_place_model.dart';
import '../data/services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider({CatalogService? catalogService})
      : _catalogService = catalogService ?? CatalogService();

  final CatalogService _catalogService;

  List<CarModel> _cars = const [];
  List<ExtraOptionModel> _extraOptions = const [];
  List<GratuityModel> _gratuities = const [];
  List<AdditionalStopModel> _additionalStops = const [];
  List<AirportModel> _airports = const [];
  List<AirportPickupPreferenceModel> _pickupPreferences = const [];
  List<PopularPlaceModel> _popularPlaces = const [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  List<CarModel> get cars => _cars;
  List<ExtraOptionModel> get extraOptions => _extraOptions;
  List<GratuityModel> get gratuities => _gratuities;
  List<AdditionalStopModel> get additionalStops => _additionalStops;
  List<AirportModel> get airports => _airports;
  List<AirportPickupPreferenceModel> get pickupPreferences => _pickupPreferences;
  List<PopularPlaceModel> get popularPlaces => _popularPlaces;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    await refreshCatalog();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _catalogService.fetchCars(),
        _catalogService.fetchExtraOptions(),
        _catalogService.fetchGratuities(),
        _catalogService.fetchAdditionalStops(),
        _catalogService.fetchAirports(),
        _catalogService.fetchAirportPickupPreferences(),
        _catalogService.fetchPopularPlaces(),
      ]);

      _cars = results[0] as List<CarModel>;
      _extraOptions = results[1] as List<ExtraOptionModel>;
      _gratuities = results[2] as List<GratuityModel>;
      _additionalStops = results[3] as List<AdditionalStopModel>;
      _airports = results[4] as List<AirportModel>;
      _pickupPreferences = results[5] as List<AirportPickupPreferenceModel>;
      _popularPlaces = results[6] as List<PopularPlaceModel>;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  CarModel? findCarById(int carId) {
    for (final car in _cars) {
      if (car.carId == carId) return car;
    }
    return null;
  }

  GratuityModel? defaultGratuity() {
    if (_gratuities.isEmpty) return null;
    return _gratuities.first;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

