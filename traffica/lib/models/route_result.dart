import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<String> path;
  final double totalCost;
  final double etaMinutes;
  final double? distanceKm;
  final List<LatLng> points;

  RouteResult({
    required this.path,
    required this.totalCost,
    required this.etaMinutes,
    this.distanceKm,
    required this.points,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      path: List<String>.from(json['path'] ?? []),
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      etaMinutes: (json['eta_minutes'] ?? 0.0).toDouble(),
      distanceKm: json['distance_km']?.toDouble(),
      points: [], // Will be populated separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'total_cost': totalCost,
      'eta_minutes': etaMinutes,
      'distance_km': distanceKm,
    };
  }

  String get costDisplay => '₹${totalCost.toStringAsFixed(0)}';
}