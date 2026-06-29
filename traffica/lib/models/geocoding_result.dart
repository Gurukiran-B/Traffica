import 'package:latlong2/latlong.dart';

/// Represents a geocoding result from Mapbox Geocoding API
class GeocodingResult {
  final String placeName;
  final LatLng coordinates;
  final String? address;
  final String? category;
  final double? relevance;

  GeocodingResult({
    required this.placeName,
    required this.coordinates,
    this.address,
    this.category,
    this.relevance,
  });

  /// Factory constructor to create GeocodingResult from Mapbox API response
  factory GeocodingResult.fromMapboxJson(Map<String, dynamic> json) {
    final center = json['center'] as List<dynamic>;
    final context = json['context'] as List<dynamic>?;

    String? address;
    String? category;

    // Extract address and category from context
    if (context != null) {
      for (var item in context) {
        final id = item['id'] as String;
        if (id.startsWith('address.')) {
          address = item['text'] as String?;
        } else if (id.startsWith('poi.')) {
          category = item['text'] as String?;
        }
      }
    }

    return GeocodingResult(
      placeName: json['place_name'] as String,
      coordinates: LatLng(center[1] as double, center[0] as double),
      address: address,
      category: category,
      relevance: json['relevance'] as double?,
    );
  }

  /// Convert to JSON for storage or API calls
  Map<String, dynamic> toJson() {
    return {
      'place_name': placeName,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      'category': category,
      'relevance': relevance,
    };
  }

  @override
  String toString() {
    return 'GeocodingResult(placeName: $placeName, coordinates: $coordinates, address: $address)';
  }
}
