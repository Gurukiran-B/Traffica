import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_result.dart';
import '../services/map_service.dart';
import '../core/config.dart';

class RealtimeNavigationService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  // Real-time route calculation using Mapbox Directions API
  static Future<RouteResult> getRealtimeRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    double trafficFactor = 1.0,
    double weatherFactor = 1.0,
    double priorityFactor = 1.0,
  }) async {
    try {
      // Use Mapbox Directions API directly
      final directions = await MapService.getDirections(
        LatLng(startLat, startLng),
        LatLng(endLat, endLng),
        profile: 'driving', // Use standard driving profile
      );

      // Convert DirectionsResult to RouteResult
      return RouteResult(
        path: directions.routePoints.map((point) => '${point.latitude},${point.longitude}').toList(),
        totalCost: directions.distance / 1000 * 8, // Rough cost calculation: ₹8 per km
        etaMinutes: directions.duration / 60, // Convert seconds to minutes
        distanceKm: directions.distance / 1000, // Convert meters to km
        points: directions.routePoints,
      );
    } catch (e) {
      throw Exception('Error getting real-time route: $e');
    }
  }

  // Update route based on current location
  static Future<RouteResult> updateRoute({
    required List<String> currentPath,
    required String currentLocation,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_route'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_path': currentPath,
          'current_location': currentLocation,
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RouteResult.fromJson(data);
      } else {
        throw Exception('Failed to update route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating route: $e');
    }
  }

  // Get real-time traffic data for a location
  static Future<Map<String, dynamic>> getRealtimeTraffic({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/realtime_traffic?lat=$lat&lng=$lng'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get traffic data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting traffic data: $e');
    }
  }

  // Get navigation instructions
  static Future<Map<String, dynamic>> getNavigationInstructions({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/navigation_instructions?start_lat=$startLat&start_lng=$startLng&end_lat=$endLat&end_lng=$endLng'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get navigation instructions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting navigation instructions: $e');
    }
  }

  // Start real-time location tracking
  static Stream<Position> startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Calculate distance between two points
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // Convert to km
  }

  // Check if user is near a waypoint
  static bool isNearWaypoint(double currentLat, double currentLng, double waypointLat, double waypointLng, double thresholdMeters) {
    final distance = Geolocator.distanceBetween(currentLat, currentLng, waypointLat, waypointLng);
    return distance <= thresholdMeters;
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Error getting current location: $e');
    }
  }
}
