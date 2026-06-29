import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../core/config.dart';

class WeatherService {
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetches weather data for a given location
  static Future<WeatherData> getWeather({String location = 'Delhi'}) async {
    final apiKey = AppConfig.openWeatherApiKey;
    // For demo purposes, return mock data if API key is not set
    if (apiKey.isEmpty || apiKey == 'YOUR_OPENWEATHER_API_KEY') {
      return _getMockWeather(location);
    }

    final url = Uri.parse(
      '$_openWeatherBaseUrl/weather?q=$location&appid=$apiKey&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WeatherData(
        location: location,
        temperature: data['main']['temp'] as double,
        condition: data['weather'][0]['description'] as String,
        humidity: data['main']['humidity'] as double,
        windSpeed: data['wind']['speed'] as double,
      );
    } else {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }
  }

  /// Mock weather data for demo purposes
  static WeatherData _getMockWeather(String location) {
    // Mock data based on location
    final mockData = {
      'Delhi': {'temp': 32.0, 'condition': 'Clear sky'},
      'Mumbai': {'temp': 28.0, 'condition': 'Partly cloudy'},
      'Bengaluru': {'temp': 25.0, 'condition': 'Light rain'},
      'Chennai': {'temp': 30.0, 'condition': 'Sunny'},
      'Hyderabad': {'temp': 29.0, 'condition': 'Clear sky'},
      'Kolkata': {'temp': 31.0, 'condition': 'Humid'},
    };

    final data = mockData[location] ?? {'temp': 27.0, 'condition': 'Clear sky'};
    return WeatherData(
      location: location,
      temperature: data['temp'] as double,
      condition: data['condition'] as String,
      humidity: 65.0, // Mock humidity
      windSpeed: 5.0, // Mock wind speed
    );
  }
}
