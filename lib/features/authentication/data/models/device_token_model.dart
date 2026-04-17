/// Model for device token registration request
class DeviceTokenRequest {
  final String token;
  final String platform;
  final bool isActive;

  const DeviceTokenRequest({
    required this.token,
    required this.platform,
    this.isActive = true,
  });

  /// Convert to JSON map for API request
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
      'is_active': isActive,
    };
  }
}

/// Model for device token response from API
class DeviceTokenResponse {
  final String id;
  final String? user;
  final String token;
  final String platform;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceTokenResponse({
    required this.id,
    this.user,
    required this.token,
    required this.platform,
    required this.isActive,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON map
  factory DeviceTokenResponse.fromJson(Map<String, dynamic> json) {
    return DeviceTokenResponse(
      id: json['id'] as String,
      user: json['user'] as String?,
      token: json['token'] as String,
      platform: json['platform'] as String,
      isActive: json['is_active'] as bool,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Enum for device platforms
enum DevicePlatform {
  android,
  ios,
  web,
  unknown;

  /// Convert to API string value
  String get apiValue {
    switch (this) {
      case DevicePlatform.android:
        return 'ANDROID';
      case DevicePlatform.ios:
        return 'IOS';
      case DevicePlatform.web:
        return 'WEB';
      case DevicePlatform.unknown:
        return '';
    }
  }

  /// Create from string
  static DevicePlatform fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ANDROID':
        return DevicePlatform.android;
      case 'IOS':
        return DevicePlatform.ios;
      case 'WEB':
        return DevicePlatform.web;
      default:
        return DevicePlatform.unknown;
    }
  }
}
