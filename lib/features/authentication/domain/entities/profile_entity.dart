/// Entity representing user profile completion data
class ProfileEntity {
  final String displayName;
  final String? phone;
  final String? address;
  final String? country;
  final String? businessName;
  final String? businessDescription;
  final DateTime? updatedAt;

  const ProfileEntity({
    required this.displayName,
    this.phone,
    this.address,
    this.country,
    this.businessName,
    this.businessDescription,
    this.updatedAt,
  });

  ProfileEntity copyWith({
    String? displayName,
    String? phone,
    String? address,
    String? country,
    String? businessName,
    String? businessDescription,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      country: country ?? this.country,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'country': country,
      'businessName': businessName,
      'businessDescription': businessDescription,
    };
  }

  /// Checks if the profile has all required fields
  bool get isComplete {
    return displayName.isNotEmpty &&
        phone != null &&
        phone!.isNotEmpty &&
        address != null &&
        address!.isNotEmpty &&
        country != null &&
        country!.isNotEmpty;
  }

  @override
  String toString() {
    return 'ProfileEntity(displayName: $displayName, country: $country)';
  }
}
