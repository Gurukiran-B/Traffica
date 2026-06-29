class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final double humidity;
  final double windSpeed;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'],
      temperature: json['temperature'].toDouble(),
      condition: json['condition'],
      humidity: json['humidity'].toDouble(),
      windSpeed: json['wind_speed'].toDouble(),
    );
  }
}
