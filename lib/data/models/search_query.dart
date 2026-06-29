/// A recorded search, kept for the satisfaction-feedback loop and lightweight
/// on-device analytics.
class SearchQuery {
  SearchQuery({
    this.id = 0,
    this.queryText = '',
    int? executedAt,
    this.executionTimeMs = 0,
    this.resultCount = 0,
    this.topScoreValue = 0,
    this.wasUserSatisfied = false,
    this.feedbackText = '',
  }) : executedAt = executedAt ?? DateTime.now().millisecondsSinceEpoch;

  int id;
  String queryText;
  int executedAt;
  int executionTimeMs;
  int resultCount;
  double topScoreValue;
  bool wasUserSatisfied;
  String feedbackText;

  Map<String, dynamic> toJson() => {
        'id': id,
        'queryText': queryText,
        'executedAt': executedAt,
        'executionTimeMs': executionTimeMs,
        'resultCount': resultCount,
        'topScoreValue': topScoreValue,
        'wasUserSatisfied': wasUserSatisfied,
        'feedbackText': feedbackText,
      };

  factory SearchQuery.fromJson(Map<String, dynamic> json) => SearchQuery(
        id: json['id'] as int? ?? 0,
        queryText: json['queryText'] as String? ?? '',
        executedAt: json['executedAt'] as int?,
        executionTimeMs: json['executionTimeMs'] as int? ?? 0,
        resultCount: json['resultCount'] as int? ?? 0,
        topScoreValue: (json['topScoreValue'] as num?)?.toDouble() ?? 0,
        wasUserSatisfied: json['wasUserSatisfied'] as bool? ?? false,
        feedbackText: json['feedbackText'] as String? ?? '',
      );
}
