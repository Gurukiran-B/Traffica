class OptimalRouteInput {
  final String fromLocation;
  final String toLocation;
  final DateTime? time;
  final String? weatherCondition;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;

  OptimalRouteInput({
    required this.fromLocation,
    required this.toLocation,
    this.time,
    this.weatherCondition,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'from_location': fromLocation,
      'to_location': toLocation,
      'time': time?.toIso8601String(),
      'weather_condition': weatherCondition,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
    };
  }
}
