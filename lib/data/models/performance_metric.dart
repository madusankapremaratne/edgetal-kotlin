/// A single benchmark sample: ingestion / retrieval / agentic latency, plus
/// precision for the evaluation suite.
class PerformanceMetric {
  PerformanceMetric({
    this.id = 0,
    this.operationType = '',
    this.operationName = '',
    this.durationMs = 0,
    this.contextData = '',
    this.resumeCount = 0,
    this.embeddingCount = 0,
    this.precision = 0,
    int? timestamp,
    this.manufacturer = '',
    this.model = '',
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  int id;
  String operationType;
  String operationName;
  int durationMs;
  String contextData;
  int resumeCount;
  int embeddingCount;
  double precision;
  int timestamp;
  String manufacturer;
  String model;

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationType': operationType,
        'operationName': operationName,
        'durationMs': durationMs,
        'contextData': contextData,
        'resumeCount': resumeCount,
        'embeddingCount': embeddingCount,
        'precision': precision,
        'timestamp': timestamp,
        'manufacturer': manufacturer,
        'model': model,
      };

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) =>
      PerformanceMetric(
        id: json['id'] as int? ?? 0,
        operationType: json['operationType'] as String? ?? '',
        operationName: json['operationName'] as String? ?? '',
        durationMs: json['durationMs'] as int? ?? 0,
        contextData: json['contextData'] as String? ?? '',
        resumeCount: json['resumeCount'] as int? ?? 0,
        embeddingCount: json['embeddingCount'] as int? ?? 0,
        precision: (json['precision'] as num?)?.toDouble() ?? 0,
        timestamp: json['timestamp'] as int?,
        manufacturer: json['manufacturer'] as String? ?? '',
        model: json['model'] as String? ?? '',
      );
}
