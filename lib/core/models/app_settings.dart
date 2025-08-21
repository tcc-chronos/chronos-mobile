enum QueryMode { lastN, dateRange }

class AppSettings {
  String ip; // ex.: 192.168.0.10
  String entityId; // ex.: urn:ngsi-ld:Chronos:ESP32:001
  String entityType; // ex.: Sensor
  String entityLabel; // para exibir no UI (entityName ou deviceId)
  List<String> attributes; // ex.: ["temperature","humidity"]

  QueryMode mode;
  int lastN; // 1..100
  String? dateFromIso; // ISO 8601 ex.: 2025-08-21T02:29:04.162Z
  String? dateToIso;

  AppSettings({
    required this.ip,
    required this.entityId,
    required this.entityType,
    required this.entityLabel,
    required this.attributes,
    required this.mode,
    required this.lastN,
    this.dateFromIso,
    this.dateToIso,
  });

  factory AppSettings.defaults() => AppSettings(
    ip: '',
    entityId: '',
    entityType: '',
    entityLabel: '',
    attributes: const [],
    mode: QueryMode.lastN,
    lastN: 10,
  );

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'entityId': entityId,
    'entityType': entityType,
    'entityLabel': entityLabel,
    'attributes': attributes,
    'mode': mode.name,
    'lastN': lastN,
    'dateFromIso': dateFromIso,
    'dateToIso': dateToIso,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    return AppSettings(
      ip: j['ip']?.toString() ?? '',
      entityId: j['entityId']?.toString() ?? '',
      entityType: j['entityType']?.toString() ?? '',
      entityLabel: j['entityLabel']?.toString() ?? '',
      attributes: (j['attributes'] as List<dynamic>? ?? []).cast<String>(),
      mode: (j['mode']?.toString() ?? 'lastN') == 'dateRange'
          ? QueryMode.dateRange
          : QueryMode.lastN,
      lastN: int.tryParse(j['lastN']?.toString() ?? '10') ?? 10,
      dateFromIso: j['dateFromIso']?.toString(),
      dateToIso: j['dateToIso']?.toString(),
    );
  }

  bool get isConfigured =>
      ip.isNotEmpty && entityId.isNotEmpty && entityType.isNotEmpty;

  AppSettings copyWith({
    String? ip,
    String? entityId,
    String? entityType,
    String? entityLabel,
    List<String>? attributes,
    QueryMode? mode,
    int? lastN,
    String? dateFromIso,
    String? dateToIso,
  }) {
    return AppSettings(
      ip: ip ?? this.ip,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      entityLabel: entityLabel ?? this.entityLabel,
      attributes: attributes ?? this.attributes,
      mode: mode ?? this.mode,
      lastN: lastN ?? this.lastN,
      dateFromIso: dateFromIso ?? this.dateFromIso,
      dateToIso: dateToIso ?? this.dateToIso,
    );
  }
}
