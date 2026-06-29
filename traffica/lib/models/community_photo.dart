class CommunityPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String? route;
  final String? description;
  final int likes;
  final int reports;
  final DateTime timestamp;

  CommunityPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.route,
    this.description,
    this.likes = 0,
    this.reports = 0,
    required this.timestamp,
  });

  factory CommunityPhoto.fromJson(Map<String, dynamic> json) {
    return CommunityPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      route: json['route'] as String?,
      description: json['description'] as String?,
      likes: json['likes'] as int? ?? 0,
      reports: json['reports'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'route': route,
      'description': description,
      'likes': likes,
      'reports': reports,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
