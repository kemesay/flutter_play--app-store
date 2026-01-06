import 'package:flutter/foundation.dart';

import '../data/models/social_media_model.dart';
import '../data/services/social_media_service.dart';

class SocialMediaProvider extends ChangeNotifier {
  SocialMediaProvider({SocialMediaService? socialMediaService})
      : _socialMediaService = socialMediaService ?? SocialMediaService();

  final SocialMediaService _socialMediaService;

  List<SocialMedia> _socialMedias = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SocialMedia> get socialMedias => _socialMedias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load social media links
  Future<void> loadSocialMedias() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _socialMedias = await _socialMediaService.fetchSocialMedias();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
