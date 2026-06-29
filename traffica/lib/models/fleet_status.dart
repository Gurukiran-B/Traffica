class VehicleStatus {
  final String id;
  final String status;
  final String currentLocation;
  final double? etaMinutes;
  final String? source;
  final String? destination;

  VehicleStatus({
    required this.id,
    required this.status,
    required this.currentLocation,
    this.etaMinutes,
    this.source,
    this.destination,
  });

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      id: json['id'],
      status: json['status'],
      currentLocation: json['current_location'],
      etaMinutes: json['eta_minutes']?.toDouble(),
      source: json['source'],
      destination: json['destination'],
    );
  }
}

class FleetStatus {
  final List<VehicleStatus> vehicles;

  FleetStatus({
    required this.vehicles,
  });

  factory FleetStatus.fromJson(Map<String, dynamic> json) {
    return FleetStatus(
      vehicles: (json['vehicles'] as List)
          .map((v) => VehicleStatus.fromJson(v))
          .toList(),
    );
  }
}
