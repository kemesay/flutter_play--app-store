import 'dart:convert';

import '../../core/network/api_client.dart';
import '../models/social_media_model.dart';

class SocialMediaService {
  final ApiClient _apiClient;

  SocialMediaService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch social media links from the API
  Future<List<SocialMedia>> fetchSocialMedias() async {
    try {
      final response = await _apiClient.get('/social-medias');

      if (response is List) {
        return response
            .map((item) => SocialMedia.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      // Return default social media links if API fails
      return _getDefaultSocialMedias();
    }
  }

  /// Get default social media links
  List<SocialMedia> _getDefaultSocialMedias() {
    return [
      SocialMedia(
        link: 'https://www.facebook.com/Oda.Black.Car.Service',
        title: 'Facebook',
      ),
      SocialMedia(
        link: 'https://www.instagram.com/oda.black.car.service/',
        title: 'Instagram',
      ),
      // SocialMedia(
      //   link:
      //       'https://www.yelp.com/biz/oda-transportation-black-car-service-anaheim',
      //   title: 'Yelp',
      // ),
      SocialMedia(
        link: 'https://x.com/OdaBlackCar',
        title: 'Twitter',
      ),
    ];
  }
}
