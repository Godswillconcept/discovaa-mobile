/// Entity representing user identification/verification data
class IdentificationEntity {
  final String? idNumber;
  final String? frontImagePath;
  final String? backImagePath;
  final bool isIdVerified;
  final bool isBusinessVerified;
  final DateTime? submittedAt;

  const IdentificationEntity({
    this.idNumber,
    this.frontImagePath,
    this.backImagePath,
    this.isIdVerified = false,
    this.isBusinessVerified = false,
    this.submittedAt,
  });

  IdentificationEntity copyWith({
    String? idNumber,
    String? frontImagePath,
    String? backImagePath,
    bool? isIdVerified,
    bool? isBusinessVerified,
    DateTime? submittedAt,
  }) {
    return IdentificationEntity(
      idNumber: idNumber ?? this.idNumber,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      isBusinessVerified: isBusinessVerified ?? this.isBusinessVerified,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  bool get isComplete {
    return idNumber != null &&
        idNumber!.isNotEmpty &&
        frontImagePath != null &&
        backImagePath != null;
  }

  @override
  String toString() {
    return 'IdentificationEntity(idNumber: $idNumber, isIdVerified: $isIdVerified, isBusinessVerified: $isBusinessVerified)';
  }
}
