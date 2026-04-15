import 'profile_enums.dart';

/// Represents business registration details for providers
class BusinessRegistration {
  final String? registrationNumber;
  final String? businessName;
  final String? businessType;
  final String? taxId;
  final String? documentUrl;
  final String? documentName;
  final VerificationStatus verificationStatus;
  final DateTime? registrationDate;

  const BusinessRegistration({
    this.registrationNumber,
    this.businessName,
    this.businessType,
    this.taxId,
    this.documentUrl,
    this.documentName,
    this.verificationStatus = VerificationStatus.unverified,
    this.registrationDate,
  });

  BusinessRegistration copyWith({
    String? registrationNumber,
    String? businessName,
    String? businessType,
    String? taxId,
    String? documentUrl,
    String? documentName,
    VerificationStatus? verificationStatus,
    DateTime? registrationDate,
  }) {
    return BusinessRegistration(
      registrationNumber: registrationNumber ?? this.registrationNumber,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      taxId: taxId ?? this.taxId,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName ?? this.documentName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registrationNumber': registrationNumber,
      'businessName': businessName,
      'businessType': businessType,
      'taxId': taxId,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'verificationStatus': verificationStatus.name,
      'registrationDate': registrationDate?.toIso8601String(),
    };
  }

  factory BusinessRegistration.fromJson(Map<String, dynamic> json) {
    return BusinessRegistration(
      registrationNumber: json['registrationNumber'],
      businessName: json['businessName'],
      businessType: json['businessType'],
      taxId: json['taxId'],
      documentUrl: json['documentUrl'],
      documentName: json['documentName'],
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : null,
    );
  }

  bool get hasDocument => documentUrl != null && documentUrl!.isNotEmpty;

  bool get isComplete {
    return registrationNumber != null &&
        registrationNumber!.isNotEmpty &&
        businessName != null &&
        businessName!.isNotEmpty;
  }
}
