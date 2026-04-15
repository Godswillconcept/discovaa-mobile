import 'profile_enums.dart';

/// Represents a professional certification or license
class Certification {
  final String id;
  final String name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? documentUrl;
  final String? documentName;
  final VerificationStatus verificationStatus;
  final String? description;

  const Certification({
    required this.id,
    required this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.documentUrl,
    this.documentName,
    this.verificationStatus = VerificationStatus.unverified,
    this.description,
  });

  Certification copyWith({
    String? id,
    String? name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? documentUrl,
    String? documentName,
    VerificationStatus? verificationStatus,
    String? description,
  }) {
    return Certification(
      id: id ?? this.id,
      name: name ?? this.name,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName ?? this.documentName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuingOrganization': issuingOrganization,
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'documentUrl': documentUrl,
      'documentName': documentName,
      'verificationStatus': verificationStatus.name,
      'description': description,
    };
  }

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      issuingOrganization: json['issuingOrganization'],
      issueDate: json['issueDate'] != null
          ? DateTime.parse(json['issueDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      documentUrl: json['documentUrl'],
      documentName: json['documentName'],
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      description: json['description'],
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  String get formattedIssueDate {
    if (issueDate == null) return 'N/A';
    return '${issueDate!.day}/${issueDate!.month}/${issueDate!.year}';
  }

  String get formattedExpiryDate {
    if (expiryDate == null) return 'No expiry';
    return '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }
}
