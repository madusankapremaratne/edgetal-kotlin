class JobCandidateLink {
  JobCandidateLink({
    required this.id,
    required this.jobId,
    required this.candidateId,
    required this.stage,
    this.fitScore = 0.0,
    this.aiThought = '',
    this.aiEvidence = '',
    this.aiConclusion = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String jobId;
  final String candidateId;
  final String stage; // 'Shortlisted', 'Interviewing', 'Offer', 'Placed'
  final double fitScore;
  final String aiThought;
  final String aiEvidence;
  final String aiConclusion;
  final DateTime updatedAt;

  JobCandidateLink copyWith({
    String? id,
    String? jobId,
    String? candidateId,
    String? stage,
    double? fitScore,
    String? aiThought,
    String? aiEvidence,
    String? aiConclusion,
    DateTime? updatedAt,
  }) {
    return JobCandidateLink(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      candidateId: candidateId ?? this.candidateId,
      stage: stage ?? this.stage,
      fitScore: fitScore ?? this.fitScore,
      aiThought: aiThought ?? this.aiThought,
      aiEvidence: aiEvidence ?? this.aiEvidence,
      aiConclusion: aiConclusion ?? this.aiConclusion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'candidateId': candidateId,
        'stage': stage,
        'fitScore': fitScore,
        'aiThought': aiThought,
        'aiEvidence': aiEvidence,
        'aiConclusion': aiConclusion,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JobCandidateLink.fromJson(Map<String, dynamic> json) {
    return JobCandidateLink(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      candidateId: json['candidateId'] as String,
      stage: json['stage'] as String? ?? 'Shortlisted',
      fitScore: (json['fitScore'] as num?)?.toDouble() ?? 0.0,
      aiThought: json['aiThought'] as String? ?? '',
      aiEvidence: json['aiEvidence'] as String? ?? '',
      aiConclusion: json['aiConclusion'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
