class JobRole {
  JobRole({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.requiredSkills = const [],
    this.location = 'Remote',
    this.employmentType = 'Full-Time',
    this.status = 'Open',
    this.shortlisted = 0,
    this.interviewing = 0,
    this.offer = 0,
    this.placed = 0,
    this.embedding,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String company;
  final String description;
  final List<String> requiredSkills;
  final String location;
  final String employmentType;
  final String status; // 'Open' or 'Filled'
  final int shortlisted;
  final int interviewing;
  final int offer;
  final int placed;
  final List<double>? embedding;
  final DateTime createdAt;

  JobRole copyWith({
    String? id,
    String? title,
    String? company,
    String? description,
    List<String>? requiredSkills,
    String? location,
    String? employmentType,
    String? status,
    int? shortlisted,
    int? interviewing,
    int? offer,
    int? placed,
    List<double>? embedding,
    DateTime? createdAt,
  }) {
    return JobRole(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      location: location ?? this.location,
      employmentType: employmentType ?? this.employmentType,
      status: status ?? this.status,
      shortlisted: shortlisted ?? this.shortlisted,
      interviewing: interviewing ?? this.interviewing,
      offer: offer ?? this.offer,
      placed: placed ?? this.placed,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'description': description,
        'requiredSkills': requiredSkills,
        'location': location,
        'employmentType': employmentType,
        'status': status,
        'shortlisted': shortlisted,
        'interviewing': interviewing,
        'offer': offer,
        'placed': placed,
        'embedding': embedding,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JobRole.fromJson(Map<String, dynamic> json) {
    return JobRole(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String? ?? 'Internal Team',
      description: json['description'] as String? ?? '',
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: json['location'] as String? ?? 'Remote',
      employmentType: json['employmentType'] as String? ?? 'Full-Time',
      status: json['status'] as String? ?? 'Open',
      shortlisted: json['shortlisted'] as int? ?? 0,
      interviewing: json['interviewing'] as int? ?? 0,
      offer: json['offer'] as int? ?? 0,
      placed: json['placed'] as int? ?? 0,
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
