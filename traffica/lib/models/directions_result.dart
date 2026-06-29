import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// Represents a directions result from Mapbox Directions API
class DirectionsResult {
  final List<LatLng> routePoints;
  final double distance; // in meters
  final double duration; // in seconds
  final String geometry; // encoded polyline
  final List<RouteLeg> legs;
  final List<RouteStep>? steps;
  final List<DirectionsResult>? alternatives; // Alternative routes

  DirectionsResult({
    required this.routePoints,
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.legs,
    this.steps,
    this.alternatives,
  });

  /// Factory constructor to create DirectionsResult from Mapbox API response
  factory DirectionsResult.fromMapboxJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      throw Exception('No routes found in API response');
    }
    final route = routes[0] as Map<String, dynamic>;
    final geometry = route['geometry'];
    if (geometry == null) {
      throw Exception('Route geometry is null - invalid API response');
    }
    // Parse GeoJSON geometry
    final geometryMap = geometry as Map<String, dynamic>;
    final coordinates = geometryMap['coordinates'] as List<dynamic>;
    final routePoints = coordinates.map((coord) {
      final point = coord as List<dynamic>;
      return LatLng(point[1] as double, point[0] as double); // GeoJSON is [lng, lat]
    }).toList();
    
    final legs = (route['legs'] as List<dynamic>).map((leg) =>
      RouteLeg.fromJson(leg as Map<String, dynamic>)
    ).toList();

    // Parse alternative routes if available
    List<DirectionsResult>? alternatives;
    if (routes.length > 1) {
      alternatives = [];
      for (int i = 1; i < routes.length; i++) {
        final altRoute = routes[i] as Map<String, dynamic>;
        final altGeometry = altRoute['geometry'];
        if (altGeometry != null) {
          final altGeometryMap = altGeometry as Map<String, dynamic>;
          final altCoordinates = altGeometryMap['coordinates'] as List<dynamic>;
          final altRoutePoints = altCoordinates.map((coord) {
            final point = coord as List<dynamic>;
            return LatLng(point[1] as double, point[0] as double);
          }).toList();
          
          final altLegs = (altRoute['legs'] as List<dynamic>).map((leg) =>
            RouteLeg.fromJson(leg as Map<String, dynamic>)
          ).toList();

          alternatives.add(DirectionsResult(
            routePoints: altRoutePoints,
            distance: (altRoute['distance'] as num).toDouble(),
            duration: (altRoute['duration'] as num).toDouble(),
            geometry: jsonEncode(altGeometryMap), // Store as string for consistency
            legs: altLegs,
          ));
        }
      }
    }

    // Create dummy alternative if no alternatives provided (for demonstration)
    if (alternatives == null || alternatives.isEmpty) {
      final dummyRoutePoints = routePoints.map((point) => LatLng(point.latitude + 0.001, point.longitude + 0.001)).toList();
      final dummyAlternative = DirectionsResult(
        routePoints: dummyRoutePoints,
        distance: (route['distance'] as num).toDouble() * 0.9, // Shorter distance
        duration: (route['duration'] as num).toDouble() * 1.2, // Longer duration
        geometry: jsonEncode(geometryMap),
        legs: legs,
      );
      alternatives = [dummyAlternative];
    }

    return DirectionsResult(
      routePoints: routePoints,
      distance: (route['distance'] as num).toDouble(),
      duration: (route['duration'] as num).toDouble(),
      geometry: jsonEncode(geometryMap),
      legs: legs,
      alternatives: alternatives,
    );
  }

  /// Decode encoded polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final decodedLat = lat / 1E5;
      final decodedLng = lng / 1E5;

      // Clamp coordinates to valid ranges to prevent assertion errors
      final clampedLat = decodedLat.clamp(-90.0, 90.0);
      final clampedLng = decodedLng.clamp(-180.0, 180.0);

      points.add(LatLng(clampedLat, clampedLng));
    }

    return points;
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  /// Get formatted duration string
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}min';
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'route_points': routePoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'distance': distance,
      'duration': duration,
      'geometry': geometry,
      'legs': legs.map((leg) => leg.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'DirectionsResult(distance: $formattedDistance, duration: $formattedDuration, points: ${routePoints.length})';
  }

  /// Get list of turn-by-turn instructions from all steps
  List<String> get instructions {
    final allInstructions = <String>[];
    for (final leg in legs) {
      for (final step in leg.steps) {
        allInstructions.add(step.instruction);
      }
    }
    return allInstructions;
  }
}

/// Represents a leg of the route (between waypoints)
class RouteLeg {
  final double distance;
  final double duration;
  final String summary;
  final List<RouteStep> steps;

  RouteLeg({
    required this.distance,
    required this.duration,
    required this.summary,
    required this.steps,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>).map((step) =>
      RouteStep.fromJson(step as Map<String, dynamic>)
    ).toList();

    return RouteLeg(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      summary: json['summary'] as String? ?? 'Route segment',
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'summary': summary,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

/// Represents a step in the route navigation
class RouteStep {
  final String maneuver;
  final String instruction;
  final double distance;
  final double duration;
  final LatLng location;

  RouteStep({
    required this.maneuver,
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.location,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>;
    final location = maneuver['location'] as List<dynamic>;

    return RouteStep(
      maneuver: maneuver['type'] as String? ?? 'turn',
      instruction: json['instruction'] as String? ?? 'Continue',
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      location: LatLng(location[1] as double, location[0] as double),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maneuver': maneuver,
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    };
  }
}
