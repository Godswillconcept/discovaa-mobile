/// Entity representing user identification/verification data
class IdentificationEntity {
  final String? idNumber;
  final String? idType; // e.g., 'NIN', 'Passport', 'Driver License'
  final String? frontImagePath;
  final String? backImagePath;
  final bool isIdVerified;
  final bool isBusinessVerified;
  final bool isIdentityVerified; // Full identity verification status
  final bool skippedVerification; // Track if user skipped verification
  final DateTime? submittedAt;
  final DateTime? skippedAt; // When user skipped verification

  const IdentificationEntity({
    this.idNumber,
    this.idType,
    this.frontImagePath,
    this.backImagePath,
    this.isIdVerified = false,
    this.isBusinessVerified = false,
    this.isIdentityVerified = false,
    this.skippedVerification = false,
    this.submittedAt,
    this.skippedAt,
  });

  IdentificationEntity copyWith({
    String? idNumber,
    String? idType,
    String? frontImagePath,
    String? backImagePath,
    bool? isIdVerified,
    bool? isBusinessVerified,
    bool? isIdentityVerified,
    bool? skippedVerification,
    DateTime? submittedAt,
    DateTime? skippedAt,
  }) {
    return IdentificationEntity(
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      isBusinessVerified: isBusinessVerified ?? this.isBusinessVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      skippedVerification: skippedVerification ?? this.skippedVerification,
      submittedAt: submittedAt ?? this.submittedAt,
      skippedAt: skippedAt ?? this.skippedAt,
    );
  }

  bool get isComplete {
    return idNumber != null &&
        idNumber!.isNotEmpty &&
        frontImagePath != null &&
        backImagePath != null;
  }

  /// Check if identity verification is pending (not verified and not permanently skipped)
  bool get isPending {
    return !isIdentityVerified && !skippedVerification;
  }

  @override
  String toString() {
    return 'IdentificationEntity(idNumber: $idNumber, idType: $idType, isIdVerified: $isIdVerified, isBusinessVerified: $isBusinessVerified, isIdentityVerified: $isIdentityVerified, skippedVerification: $skippedVerification)';
  }
}
