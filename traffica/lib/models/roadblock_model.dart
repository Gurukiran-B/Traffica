import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// Represents a roadblock or construction area on the map
class Roadblock {
  final String id;
  final String title;
  final String description;
  final LatLng location;
  final RoadblockType type;
  final RoadblockSeverity severity;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? reportedBy; // User ID if reported by user
  final bool isActive;
  final String? imageUrl;

  Roadblock({
    String? id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    this.severity = RoadblockSeverity.medium,
    DateTime? reportedAt,
    this.resolvedAt,
    this.reportedBy,
    this.isActive = true,
    this.imageUrl,
  }) :
    id = id ?? const Uuid().v4(),
    reportedAt = reportedAt ?? DateTime.now();

  /// Factory constructor to create Roadblock from Firestore document
  factory Roadblock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Roadblock(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      ),
      type: RoadblockType.values.firstWhere(
        (e) => e.toString() == 'RoadblockType.${data['type']}',
        orElse: () => RoadblockType.construction,
      ),
      severity: RoadblockSeverity.values.firstWhere(
        (e) => e.toString() == 'RoadblockSeverity.${data['severity']}',
        orElse: () => RoadblockSeverity.medium,
      ),
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
        ? (data['resolvedAt'] as Timestamp).toDate()
        : null,
      reportedBy: data['reportedBy'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Factory constructor to create Roadblock from JSON (for static data)
  factory Roadblock.fromJson(Map<String, dynamic> json) {
    return Roadblock(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      type: RoadblockType.values.firstWhere(
        (e) => e.toString() == 'RoadblockType.${json['type']}',
        orElse: () => RoadblockType.construction,
      ),
      severity: RoadblockSeverity.values.firstWhere(
        (e) => e.toString() == 'RoadblockSeverity.${json['severity']}',
        orElse: () => RoadblockSeverity.medium,
      ),
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
        ? DateTime.parse(json['resolvedAt'] as String)
        : null,
      reportedBy: json['reportedBy'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'reportedBy': reportedBy,
      'isActive': isActive,
      'imageUrl': imageUrl,
    };
  }

  /// Convert to JSON for static data storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'reportedAt': reportedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'reportedBy': reportedBy,
      'isActive': isActive,
      'imageUrl': imageUrl,
    };
  }

  /// Create a copy with modified fields
  Roadblock copyWith({
    String? title,
    String? description,
    LatLng? location,
    RoadblockType? type,
    RoadblockSeverity? severity,
    DateTime? resolvedAt,
    bool? isActive,
    String? imageUrl,
  }) {
    return Roadblock(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      reportedAt: reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      reportedBy: reportedBy,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Get marker color based on severity
  int get markerColor {
    switch (severity) {
      case RoadblockSeverity.low:
        return 0xFF4CAF50; // Green
      case RoadblockSeverity.medium:
        return 0xFFFF9800; // Orange
      case RoadblockSeverity.high:
        return 0xFFF44336; // Red
      case RoadblockSeverity.critical:
        return 0xFF9C27B0; // Purple
    }
  }

  /// Get icon based on type
  String get iconName {
    switch (type) {
      case RoadblockType.construction:
        return 'construction';
      case RoadblockType.accident:
        return 'car_crash';
      case RoadblockType.roadwork:
        return 'engineering';
      case RoadblockType.flooding:
        return 'water';
      case RoadblockType.other:
        return 'warning';
    }
  }

  @override
  String toString() {
    return 'Roadblock(id: $id, title: $title, type: $type, severity: $severity, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Roadblock && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of roadblocks
enum RoadblockType {
  construction,
  accident,
  roadwork,
  flooding,
  other,
}

/// Severity levels for roadblocks
enum RoadblockSeverity {
  low,
  medium,
  high,
  critical,
}

/// Extension methods for enums
extension RoadblockTypeExtension on RoadblockType {
  String get displayName {
    switch (this) {
      case RoadblockType.construction:
        return 'Construction';
      case RoadblockType.accident:
        return 'Accident';
      case RoadblockType.roadwork:
        return 'Road Work';
      case RoadblockType.flooding:
        return 'Flooding';
      case RoadblockType.other:
        return 'Other';
    }
  }
}

extension RoadblockSeverityExtension on RoadblockSeverity {
  String get displayName {
    switch (this) {
      case RoadblockSeverity.low:
        return 'Low';
      case RoadblockSeverity.medium:
        return 'Medium';
      case RoadblockSeverity.high:
        return 'High';
      case RoadblockSeverity.critical:
        return 'Critical';
    }
  }
}
