/// A candidate resume / career document in the local store.
///
/// Mirrors the original `Resume` ObjectBox entity. Everything lives on-device;
/// no field ever leaves the handset (GDPR by design).
class Resume {
  Resume({
    this.id = 0,
    this.resumeId = '',
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.rawText = '',
    this.summary = '',
    this.skills = '',
    this.experience = '',
    this.education = '',
    this.certifications = '',
    this.sourceFile = '',
    this.fileFormat = 'text',
    this.category = '',
    int? createdAt,
    int? updatedAt,
    this.embeddedAt = 0,
    this.isEmbedded = false,
    this.processingStatus = 'pending',
    this.errorMessage = '',
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  int id;
  String resumeId;
  String fullName;
  String email;
  String phoneNumber;

  String rawText;
  String summary;
  String skills;
  String experience;
  String education;
  String certifications;

  String sourceFile;
  String fileFormat;
  String category;

  int createdAt;
  int updatedAt;
  int embeddedAt;
  bool isEmbedded;
  String processingStatus;
  String errorMessage;

  /// First letter for the avatar monogram.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<String> get skillList => skills
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Resume copyWith({
    String? processingStatus,
    String? errorMessage,
    bool? isEmbedded,
    int? embeddedAt,
  }) {
    return Resume(
      id: id,
      resumeId: resumeId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      rawText: rawText,
      summary: summary,
      skills: skills,
      experience: experience,
      education: education,
      certifications: certifications,
      sourceFile: sourceFile,
      fileFormat: fileFormat,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      embeddedAt: embeddedAt ?? this.embeddedAt,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      processingStatus: processingStatus ?? this.processingStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'resumeId': resumeId,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'rawText': rawText,
        'summary': summary,
        'skills': skills,
        'experience': experience,
        'education': education,
        'certifications': certifications,
        'sourceFile': sourceFile,
        'fileFormat': fileFormat,
        'category': category,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'embeddedAt': embeddedAt,
        'isEmbedded': isEmbedded,
        'processingStatus': processingStatus,
        'errorMessage': errorMessage,
      };

  factory Resume.fromJson(Map<String, dynamic> json) => Resume(
        id: json['id'] as int? ?? 0,
        resumeId: json['resumeId'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        rawText: json['rawText'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        skills: json['skills'] as String? ?? '',
        experience: json['experience'] as String? ?? '',
        education: json['education'] as String? ?? '',
        certifications: json['certifications'] as String? ?? '',
        sourceFile: json['sourceFile'] as String? ?? '',
        fileFormat: json['fileFormat'] as String? ?? 'text',
        category: json['category'] as String? ?? '',
        createdAt: json['createdAt'] as int?,
        updatedAt: json['updatedAt'] as int?,
        embeddedAt: json['embeddedAt'] as int? ?? 0,
        isEmbedded: json['isEmbedded'] as bool? ?? false,
        processingStatus: json['processingStatus'] as String? ?? 'pending',
        errorMessage: json['errorMessage'] as String? ?? '',
      );
}
