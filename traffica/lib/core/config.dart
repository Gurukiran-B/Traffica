import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = kIsWeb 
      ? 'http://127.0.0.1:8000' 
      : String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://192.168.29.14:8000',
        );

  // Mapbox API Configuration
  static String get mapboxAccessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/streets-v12';

  static String? getMapboxToken() {
    return mapboxAccessToken;
  }

  // OpenWeatherMap API Configuration
  static String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
}


