class DeliverySearchResult {
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String deliveryType; // "standard", "express", "same_day"
  final double deliveryFee;
  final int estimatedTimeMinutes;

  DeliverySearchResult({
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.deliveryType,
    required this.deliveryFee,
    required this.estimatedTimeMinutes,
  });

  factory DeliverySearchResult.fromJson(Map<String, dynamic> json) {
    return DeliverySearchResult(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      deliveryType: json['deliveryType'],
      deliveryFee: json['deliveryFee'],
      estimatedTimeMinutes: json['estimatedTimeMinutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'deliveryType': deliveryType,
      'deliveryFee': deliveryFee,
      'estimatedTimeMinutes': estimatedTimeMinutes,
    };
  }
}
