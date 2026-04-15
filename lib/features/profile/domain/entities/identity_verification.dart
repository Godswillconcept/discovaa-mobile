import 'profile_enums.dart';

/// Represents identity verification details
class IdentityVerification {
  final String? idNumber;
  final String? idFrontImageUrl;
  final String? idBackImageUrl;
  final String? idFrontImageName;
  final String? idBackImageName;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const IdentityVerification({
    this.idNumber,
    this.idFrontImageUrl,
    this.idBackImageUrl,
    this.idFrontImageName,
    this.idBackImageName,
    this.status = VerificationStatus.unverified,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  IdentityVerification copyWith({
    String? idNumber,
    String? idFrontImageUrl,
    String? idBackImageUrl,
    String? idFrontImageName,
    String? idBackImageName,
    VerificationStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return IdentityVerification(
      idNumber: idNumber ?? this.idNumber,
      idFrontImageUrl: idFrontImageUrl ?? this.idFrontImageUrl,
      idBackImageUrl: idBackImageUrl ?? this.idBackImageUrl,
      idFrontImageName: idFrontImageName ?? this.idFrontImageName,
      idBackImageName: idBackImageName ?? this.idBackImageName,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idNumber': idNumber,
      'idFrontImageUrl': idFrontImageUrl,
      'idBackImageUrl': idBackImageUrl,
      'idFrontImageName': idFrontImageName,
      'idBackImageName': idBackImageName,
      'status': status.name,
      'submittedAt': submittedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    return IdentityVerification(
      idNumber: json['idNumber'],
      idFrontImageUrl: json['idFrontImageUrl'],
      idBackImageUrl: json['idBackImageUrl'],
      idFrontImageName: json['idFrontImageName'],
      idBackImageName: json['idBackImageName'],
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VerificationStatus.unverified,
      ),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  bool get isComplete {
    return idNumber != null &&
        idNumber!.isNotEmpty &&
        idFrontImageUrl != null &&
        idFrontImageUrl!.isNotEmpty;
  }

  bool get hasFrontImage => idFrontImageUrl != null && idFrontImageUrl!.isNotEmpty;

  bool get hasBackImage => idBackImageUrl != null && idBackImageUrl!.isNotEmpty;
}
