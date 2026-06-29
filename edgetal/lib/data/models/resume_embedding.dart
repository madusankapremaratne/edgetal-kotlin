/// A vector embedding for one segment (summary / skills / experience / …) of a
/// resume. Stored locally and scanned by the on-device vector search engine.
class ResumeEmbedding {
  ResumeEmbedding({
    this.id = 0,
    this.resumeId = 0,
    this.segmentId = '',
    this.segmentType = '',
    this.segmentText = '',
    List<double>? embedding,
    this.embeddingModel = 'mediapipe-text-embedder',
    this.embeddingDimension = 512,
    int? createdAt,
    this.confidenceScore = 0,
  })  : embedding = embedding ?? const [],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  int id;
  int resumeId;
  String segmentId;
  String segmentType;
  String segmentText;
  List<double> embedding;
  String embeddingModel;
  int embeddingDimension;
  int createdAt;
  double confidenceScore;

  Map<String, dynamic> toJson() => {
        'id': id,
        'resumeId': resumeId,
        'segmentId': segmentId,
        'segmentType': segmentType,
        'segmentText': segmentText,
        'embedding': embedding,
        'embeddingModel': embeddingModel,
        'embeddingDimension': embeddingDimension,
        'createdAt': createdAt,
        'confidenceScore': confidenceScore,
      };

  factory ResumeEmbedding.fromJson(Map<String, dynamic> json) =>
      ResumeEmbedding(
        id: json['id'] as int? ?? 0,
        resumeId: json['resumeId'] as int? ?? 0,
        segmentId: json['segmentId'] as String? ?? '',
        segmentType: json['segmentType'] as String? ?? '',
        segmentText: json['segmentText'] as String? ?? '',
        embedding: (json['embedding'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        embeddingModel: json['embeddingModel'] as String? ?? '',
        embeddingDimension: json['embeddingDimension'] as int? ?? 512,
        createdAt: json['createdAt'] as int?,
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      );
}
