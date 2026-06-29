import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../core/config.dart';
import '../models/geocoding_result.dart';
import '../models/directions_result.dart';

/// Service class for Mapbox API integrations
/// Handles geocoding, directions, and other map-related API calls
class MapService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Search for places using Mapbox Geocoding API
  /// Returns a list of geocoding results based on the search query
  static Future<List<GeocodingResult>> searchPlaces(
    String query, {
    LatLng? proximity,
    String? country = 'IN', // Default to India
    int limit = 5,
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      final baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

      // Build query parameters
      final params = <String, dynamic>{
        'access_token': token,
        'limit': limit.toString(),
        'country': country!,
        'types': 'address,poi,place', // Include addresses, points of interest, and places
      };

      // Add proximity if provided
      if (proximity != null) {
        params['proximity'] = '${proximity.longitude},${proximity.latitude}';
      }

      final url = '$baseUrl/${Uri.encodeComponent(query)}.json';
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        return features.map((feature) =>
          GeocodingResult.fromMapboxJson(feature as Map<String, dynamic>)
        ).toList();
      } else {
        throw Exception('Geocoding API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  /// Get search suggestions using Mapbox Search Box API (autocomplete)
  /// Returns a list of search suggestions for autocomplete functionality
  static Future<List<Map<String, dynamic>>> getSearchSuggestions(
    String query, {
    LatLng? proximity,
    String? country = 'IN',
    int limit = 5,
    String? language = 'en',
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/search/searchbox/v1/suggest';

      final params = <String, dynamic>{
        'access_token': token,
        'q': query,
        'limit': limit.toString(),
        'country': country!,
        'language': language!,
        'types': 'place,postcode,locality,neighborhood,address,poi',
      };

      // Add proximity if provided
      if (proximity != null) {
        params['proximity'] = '${proximity.longitude},${proximity.latitude}';
      }

      print('Making search suggestions request for: $query');
      final response = await _dio.get(baseUrl, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        print('Got ${suggestions.length} search suggestions');
        return suggestions.map((suggestion) => suggestion as Map<String, dynamic>).toList();
      } else {
        throw Exception('Search Box API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in getSearchSuggestions: $e');
      throw Exception('Failed to get search suggestions: $e');
    }
  }

  /// Retrieve full search result using Mapbox Search Box API
  /// Takes a suggestion map_id and returns detailed place information
  static Future<Map<String, dynamic>> retrieveSearchResult(String mapboxId) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId';

      final params = <String, dynamic>{
        'access_token': token,
      };

      print('Retrieving search result for mapbox_id: $mapboxId');
      final response = await _dio.get(baseUrl, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('Successfully retrieved search result');
        return data;
      } else {
        throw Exception('Search Box retrieve API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in retrieveSearchResult: $e');
      throw Exception('Failed to retrieve search result: $e');
    }
  }

  /// Forward geocoding using Mapbox Search Box API
  /// Returns detailed place information for a search query
  static Future<List<Map<String, dynamic>>> forwardGeocodeSearchBox(
    String query, {
    LatLng? proximity,
    String? country = 'IN',
    int limit = 5,
    String? language = 'en',
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/search/geocode/v6/forward';

      final params = <String, dynamic>{
        'access_token': token,
        'q': query,
        'limit': limit.toString(),
        'country': country!,
        'language': language!,
        'types': 'place,postcode,locality,neighborhood,address,poi',
      };

      // Add proximity if provided
      if (proximity != null) {
        params['proximity'] = '${proximity.longitude},${proximity.latitude}';
      }

      print('Making forward geocoding request for: $query');
      final response = await _dio.get(baseUrl, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        print('Got ${features.length} geocoding results');
        return features.map((feature) => feature as Map<String, dynamic>).toList();
      } else {
        throw Exception('Search Box forward geocoding API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in forwardGeocodeSearchBox: $e');
      throw Exception('Failed to forward geocode: $e');
    }
  }

  /// Get directions between two points using Mapbox Directions API
  /// Returns the optimal driving route
  static Future<DirectionsResult> getDirections(
    LatLng origin,
    LatLng destination, {
    List<LatLng>? waypoints,
    String profile = 'driving-traffic', // Use traffic-aware routing
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

      // Build coordinates string: start...waypoints...end
      final coordinates = <String>[];
      coordinates.add('${origin.longitude},${origin.latitude}');

      if (waypoints != null) {
        for (final waypoint in waypoints) {
          coordinates.add('${waypoint.longitude},${waypoint.latitude}');
        }
      }

      coordinates.add('${destination.longitude},${destination.latitude}');
      final coordsString = coordinates.join(';');

      final url = '$baseUrl/$profile/$coordsString';
      final params = <String, dynamic>{
        'access_token': token,
        'geometries': 'geojson', // Use GeoJSON for easier parsing
        'overview': 'full', // Include full route geometry
        'steps': 'true', // Include turn-by-turn instructions
        'voice_instructions': 'true', // Include voice guidance
        'banner_instructions': 'true', // Include banner instructions
        'roundabout_exits': 'true', // Include roundabout exit information
        'voice_units': 'metric', // Use metric units
        'alternatives': 'true', // Request alternative routes for shortest path option
        'continue_straight': 'true', // Prefer continuing straight at waypoints
        'annotations': 'distance,duration,speed,congestion', // Include traffic data
        'language': 'en', // Specify language for instructions
      };

      print('Making directions request to: $url');
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>;

        if (routes.isNotEmpty) {
          final result = DirectionsResult.fromMapboxJson(data);
          print('Successfully got directions with ${result.routePoints.length} points');

          // Check for alternative routes and parse them
          if (routes.length > 1) {
            final alternatives = <DirectionsResult>[];
            for (int i = 1; i < routes.length; i++) {
              final altRoute = routes[i] as Map<String, dynamic>;
              final altGeometry = altRoute['geometry'];
              if (altGeometry == null) {
                print('Skipping alternative route $i due to null geometry');
                continue;
              }
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
                geometry: jsonEncode(altGeometryMap),
                legs: altLegs,
              ));
            }
            // Return the main route with alternatives
            return DirectionsResult(
              routePoints: result.routePoints,
              distance: result.distance,
              duration: result.duration,
              geometry: result.geometry,
              legs: result.legs,
              alternatives: alternatives,
            );
          }

          return result;
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('Directions API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in getDirections: $e');
      throw Exception('Failed to get directions: $e');
    }
  }

  /// Get reverse geocoding for coordinates (address from lat/lng)
  static Future<GeocodingResult?> reverseGeocode(LatLng coordinates) async {
    try {
      final token = AppConfig.getMapboxToken();
      final baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

      final url = '$baseUrl/${coordinates.longitude},${coordinates.latitude}.json';
      final params = <String, dynamic>{
        'access_token': token,
        'limit': 1,
        'types': 'address,poi,place',
      };

      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        if (features.isNotEmpty) {
          return GeocodingResult.fromMapboxJson(features[0] as Map<String, dynamic>);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to reverse geocode: $e');
    }
  }

  /// Get optimized route for multiple waypoints using Mapbox Optimization API V1
  static Future<DirectionsResult> getOptimizedRoute(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints, {
    String profile = 'driving',
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/optimized-trips/v1/mapbox';

      // Build coordinates array: [origin, ...waypoints, destination]
      final coordinates = <List<double>>[];
      coordinates.add([origin.longitude, origin.latitude]);
      for (final waypoint in waypoints) {
        coordinates.add([waypoint.longitude, waypoint.latitude]);
      }
      coordinates.add([destination.longitude, destination.latitude]);

      final url = '$baseUrl/$profile';
      final params = <String, dynamic>{
        'access_token': token,
        'roundtrip': 'false', // Not a round trip
        'source': 'first', // Start at first coordinate
        'destination': 'last', // End at last coordinate
        'overview': 'full', // Include full route geometry
        'steps': 'true', // Include turn-by-turn instructions
        'geometries': 'polyline', // Use encoded polyline
        'annotations': 'distance,duration,speed', // Include route annotations
        'language': 'en',
      };

      final requestBody = {
        'locations': coordinates,
        'profile': profile,
      };

      print('Making optimization request to: $url');
      final response = await _dio.post(
        url,
        queryParameters: params,
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final trips = data['trips'] as List<dynamic>?;

        if (trips != null && trips.isNotEmpty) {
          final trip = trips[0] as Map<String, dynamic>;
          final waypointsOrder = data['waypoints'] as List<dynamic>;

          // Reorder coordinates based on optimization
          final optimizedCoordinates = <LatLng>[];
          for (final waypoint in waypointsOrder) {
            final location = waypoint['location'] as List<dynamic>;
            optimizedCoordinates.add(LatLng(location[1] as double, location[0] as double));
          }

          // Decode the route geometry
          final geometry = trip['geometry'] as String;
          final routePoints = _decodePolyline(geometry);

          // Parse legs
          final legs = (trip['legs'] as List<dynamic>).map((leg) =>
            RouteLeg.fromJson(leg as Map<String, dynamic>)
          ).toList();

          final result = DirectionsResult(
            routePoints: routePoints,
            distance: (trip['distance'] as num).toDouble(),
            duration: (trip['duration'] as num).toDouble(),
            geometry: geometry,
            legs: legs,
          );

          print('Successfully got optimized route with ${routePoints.length} points');
          return result;
        } else {
          throw Exception('No optimized trips found');
        }
      } else {
        throw Exception('Optimization API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in getOptimizedRoute: $e');
      // Fallback to standard directions if optimization fails
      print('Falling back to standard directions');
      return getDirections(origin, destination, waypoints: waypoints, profile: profile);
    }
  }

  /// Get traffic-aware ETA between two points
  static Future<Map<String, dynamic>> getTrafficETA(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final directions = await getDirections(origin, destination, profile: 'driving-traffic');

      return {
        'duration': directions.duration,
        'durationFormatted': directions.formattedDuration,
        'distance': directions.distance,
        'distanceFormatted': directions.formattedDistance,
        'routePoints': directions.routePoints,
      };
    } catch (e) {
      throw Exception('Failed to get traffic ETA: $e');
    }
  }

  /// Check if coordinates are within Bangalore city limits (approximate)
  static bool isWithinBangalore(LatLng coordinates) {
    // Approximate Bangalore bounds
    const double bangaloreNorth = 13.0827;
    const double bangaloreSouth = 12.8346;
    const double bangaloreEast = 77.8498;
    const double bangaloreWest = 77.3667;

    return coordinates.latitude >= bangaloreSouth &&
           coordinates.latitude <= bangaloreNorth &&
           coordinates.longitude >= bangaloreWest &&
           coordinates.longitude <= bangaloreEast;
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

  /// Get static map image URL for a location
  static String getStaticMapUrl(
    LatLng center, {
    int width = 400,
    int height = 300,
    int zoom = 12,
    List<LatLng>? markers,
  }) {
    final token = AppConfig.getMapboxToken();
    final baseUrl = 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/static';

    // Add markers if provided
    String markerString = '';
    if (markers != null && markers.isNotEmpty) {
      final markerParams = markers.map((marker) =>
        'pin-s+ff0000(${marker.longitude},${marker.latitude})'
      ).join(',');
      markerString = '$markerParams/';
    }

    final url = '$baseUrl/$markerString${center.longitude},${center.latitude},$zoom/${width}x$height@2x?access_token=$token';
    return url;
  }

  /// Match GPS traces to the road network using Mapbox Map Matching API
  /// Returns the matched route with snapped coordinates and route information
  static Future<DirectionsResult> matchRoute(
    List<LatLng> trace, {
    String profile = 'driving',
    double? radius,
    bool tidy = true,
    String geometries = 'polyline',
    String overview = 'full',
    String steps = 'true',
    String annotations = 'distance,duration',
    String language = 'en',
  }) async {
    try {
      final token = AppConfig.getMapboxToken();
      if (token == null || token.isEmpty) {
        throw Exception('Mapbox token not configured');
      }

      final baseUrl = 'https://api.mapbox.com/matching/v5/mapbox';

      // Build coordinates string from trace
      final coordinates = trace.map((point) =>
        '${point.longitude},${point.latitude}'
      ).join(';');

      final url = '$baseUrl/$profile/$coordinates';
      final params = <String, dynamic>{
        'access_token': token,
        'geometries': geometries,
        'overview': overview,
        'steps': steps,
        'annotations': annotations,
        'language': language,
        'tidy': tidy.toString(),
      };

      // Add radius if provided
      if (radius != null) {
        params['radiuses'] = List.filled(trace.length, radius.toString()).join(';');
      }

      print('Making map matching request for ${trace.length} points');
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final matchings = data['matchings'] as List<dynamic>?;

        if (matchings != null && matchings.isNotEmpty) {
          final matching = matchings[0] as Map<String, dynamic>;
          final geometry = matching['geometry'] as String;
          final routePoints = _decodePolyline(geometry);

          // Parse legs if available
          final legs = (matching['legs'] as List<dynamic>?)?.map((leg) =>
            RouteLeg.fromJson(leg as Map<String, dynamic>)
          ).toList() ?? [];

          final result = DirectionsResult(
            routePoints: routePoints,
            distance: (matching['distance'] as num).toDouble(),
            duration: (matching['duration'] as num).toDouble(),
            geometry: geometry,
            legs: legs,
          );

          print('Successfully matched route with ${routePoints.length} points');
          return result;
        } else {
          throw Exception('No matching routes found');
        }
      } else {
        throw Exception('Map Matching API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in matchRoute: $e');
      throw Exception('Failed to match route: $e');
    }
  }
}
