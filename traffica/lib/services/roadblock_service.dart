import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/roadblock_model.dart';

/// Service class for managing roadblocks
/// Handles both static JSON data and Firebase Firestore for user-reported roadblocks
class RoadblockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load static roadblocks from JSON file
  static Future<List<Roadblock>> loadStaticRoadblocks() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/roadblocks.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      return jsonList.map((json) => Roadblock.fromJson(json)).toList();
    } catch (e) {
      // Return empty list if file not found or parsing fails
      return [];
    }
  }

  /// Get all active roadblocks (static + user-reported)
  static Future<List<Roadblock>> getAllActiveRoadblocks() async {
    final staticRoadblocks = await loadStaticRoadblocks();
    final userRoadblocks = await getUserReportedRoadblocks();

    return [...staticRoadblocks, ...userRoadblocks];
  }

  /// Get user-reported roadblocks from Firebase
  static Future<List<Roadblock>> getUserReportedRoadblocks() async {
    try {
      final querySnapshot = await _firestore
          .collection('roadblocks')
          .where('isActive', isEqualTo: true)
          .orderBy('reportedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Roadblock.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Return empty list if Firebase fails
      return [];
    }
  }

  /// Report a new roadblock
  static Future<String> reportRoadblock({
    required String title,
    required String description,
    required RoadblockType type,
    required RoadblockSeverity severity,
    required double latitude,
    required double longitude,
    String? reportedBy,
    String? imageUrl,
  }) async {
    try {
      final roadblock = Roadblock(
        title: title,
        description: description,
        type: type,
        severity: severity,
        location: LatLng(latitude, longitude),
        reportedBy: reportedBy,
        imageUrl: imageUrl,
      );

      final docRef = await _firestore
          .collection('roadblocks')
          .add(roadblock.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to report roadblock: $e');
    }
  }

  /// Update roadblock status (mark as resolved)
  static Future<void> resolveRoadblock(String roadblockId) async {
    try {
      await _firestore.collection('roadblocks').doc(roadblockId).update({
        'isActive': false,
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to resolve roadblock: $e');
    }
  }

  /// Get roadblocks within a certain radius of a location
  static Future<List<Roadblock>> getRoadblocksNearLocation(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      final allRoadblocks = await getAllActiveRoadblocks();

      return allRoadblocks.where((roadblock) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          roadblock.location.latitude,
          roadblock.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get roadblocks along a route (within certain distance of route points)
  static Future<List<Roadblock>> getRoadblocksAlongRoute(
    List<LatLng> routePoints,
    double maxDistanceKm,
  ) async {
    try {
      final allRoadblocks = await getAllActiveRoadblocks();
      final routeRoadblocks = <Roadblock>[];

      for (final roadblock in allRoadblocks) {
        // Check if roadblock is within maxDistanceKm of any route point
        bool isNearRoute = false;

        for (final routePoint in routePoints) {
          final distance = _calculateDistance(
            routePoint.latitude,
            routePoint.longitude,
            roadblock.location.latitude,
            roadblock.location.longitude,
          );

          if (distance <= maxDistanceKm) {
            isNearRoute = true;
            break;
          }
        }

        if (isNearRoute) {
          routeRoadblocks.add(roadblock);
        }
      }

      return routeRoadblocks;
    } catch (e) {
      return [];
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Get roadblock statistics
  static Future<Map<String, int>> getRoadblockStats() async {
    try {
      final allRoadblocks = await getAllActiveRoadblocks();

      final stats = {
        'total': allRoadblocks.length,
        'construction': allRoadblocks.where((rb) => rb.type == RoadblockType.construction).length,
        'accident': allRoadblocks.where((rb) => rb.type == RoadblockType.accident).length,
        'roadwork': allRoadblocks.where((rb) => rb.type == RoadblockType.roadwork).length,
        'flooding': allRoadblocks.where((rb) => rb.type == RoadblockType.flooding).length,
        'other': allRoadblocks.where((rb) => rb.type == RoadblockType.other).length,
        'high': allRoadblocks.where((rb) => rb.severity == RoadblockSeverity.high).length,
        'critical': allRoadblocks.where((rb) => rb.severity == RoadblockSeverity.critical).length,
      };

      return stats;
    } catch (e) {
      return {
        'total': 0,
        'construction': 0,
        'accident': 0,
        'roadwork': 0,
        'flooding': 0,
        'other': 0,
        'high': 0,
        'critical': 0,
      };
    }
  }

  /// Search roadblocks by type or severity
  static Future<List<Roadblock>> searchRoadblocks({
    RoadblockType? type,
    RoadblockSeverity? severity,
    String? keyword,
  }) async {
    try {
      final allRoadblocks = await getAllActiveRoadblocks();

      return allRoadblocks.where((roadblock) {
        // Filter by type
        if (type != null && roadblock.type != type) {
          return false;
        }

        // Filter by severity
        if (severity != null && roadblock.severity != severity) {
          return false;
        }

        // Filter by keyword
        if (keyword != null && keyword.isNotEmpty) {
          final lowerKeyword = keyword.toLowerCase();
          final matchesTitle = roadblock.title.toLowerCase().contains(lowerKeyword);
          final matchesDescription = roadblock.description.toLowerCase().contains(lowerKeyword);

          if (!matchesTitle && !matchesDescription) {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
