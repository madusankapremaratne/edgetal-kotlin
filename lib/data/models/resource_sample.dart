/// One resource snapshot taken during a sustained-load profiling session —
/// memory / battery / CPU / thermal state, sampled on a fixed interval
/// independent of query boundaries so a single long LLM generation doesn't
/// alias the peaks (see [ResourceMonitorChannel] on the native side).
class ResourceSample {
  ResourceSample({
    this.id = 0,
    this.elapsedMs = 0,
    this.queryIndex,
    this.memPssMb = 0,
    this.memAvailMb = 0,
    this.memTotalMb = 0,
    this.batteryPct = 0,
    this.batteryCurrentMa = 0,
    this.batteryChargeCounterMah = 0,
    this.charging = false,
    this.cpuAppPct = 0,
    this.thermalStatus = 'UNKNOWN',
    this.llmBackend = 'CPU',
    this.manufacturer = '',
    this.model = '',
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  int id;
  int elapsedMs;
  int? queryIndex;
  double memPssMb;
  double memAvailMb;
  double memTotalMb;
  int batteryPct;
  double batteryCurrentMa;
  double batteryChargeCounterMah;
  bool charging;
  double cpuAppPct;
  String thermalStatus;
  String llmBackend;
  String manufacturer;
  String model;
  int timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'elapsedMs': elapsedMs,
        'queryIndex': queryIndex,
        'memPssMb': memPssMb,
        'memAvailMb': memAvailMb,
        'memTotalMb': memTotalMb,
        'batteryPct': batteryPct,
        'batteryCurrentMa': batteryCurrentMa,
        'batteryChargeCounterMah': batteryChargeCounterMah,
        'charging': charging,
        'cpuAppPct': cpuAppPct,
        'thermalStatus': thermalStatus,
        'llmBackend': llmBackend,
        'manufacturer': manufacturer,
        'model': model,
        'timestamp': timestamp,
      };

  factory ResourceSample.fromJson(Map<String, dynamic> json) => ResourceSample(
        id: json['id'] as int? ?? 0,
        elapsedMs: json['elapsedMs'] as int? ?? 0,
        queryIndex: json['queryIndex'] as int?,
        memPssMb: (json['memPssMb'] as num?)?.toDouble() ?? 0,
        memAvailMb: (json['memAvailMb'] as num?)?.toDouble() ?? 0,
        memTotalMb: (json['memTotalMb'] as num?)?.toDouble() ?? 0,
        batteryPct: json['batteryPct'] as int? ?? 0,
        batteryCurrentMa: (json['batteryCurrentMa'] as num?)?.toDouble() ?? 0,
        batteryChargeCounterMah:
            (json['batteryChargeCounterMah'] as num?)?.toDouble() ?? 0,
        charging: json['charging'] as bool? ?? false,
        cpuAppPct: (json['cpuAppPct'] as num?)?.toDouble() ?? 0,
        thermalStatus: json['thermalStatus'] as String? ?? 'UNKNOWN',
        llmBackend: json['llmBackend'] as String? ?? 'CPU',
        manufacturer: json['manufacturer'] as String? ?? '',
        model: json['model'] as String? ?? '',
        timestamp: json['timestamp'] as int?,
      );
}
