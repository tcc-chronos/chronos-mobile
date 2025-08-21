class AppSettings {
  String ip; // ex.: 192.168.0.10
  String entityId; // ex.: urn:ngsi-ld:Chronos:ESP32:001
  String entityType; // ex.: Sensor
  String entityLabel; // para exibir no UI (entityName ou deviceId)
  List<String> attributes; // ex.: ["temperature","humidity"]
  int lastN; // 1..100

  AppSettings({
    required this.ip,
    required this.entityId,
    required this.entityType,
    required this.entityLabel,
    required this.attributes,
    required this.lastN,
  });

  factory AppSettings.defaults() => AppSettings(
    ip: '',
    entityId: '',
    entityType: '',
    entityLabel: '',
    attributes: const [],
    lastN: 10,
  );

  Map<String, dynamic> toJson() => {
    'ip': ip,
    'entityId': entityId,
    'entityType': entityType,
    'entityLabel': entityLabel,
    'attributes': attributes,
    'lastN': lastN,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    return AppSettings(
      ip: j['ip']?.toString() ?? '',
      entityId: j['entityId']?.toString() ?? '',
      entityType: j['entityType']?.toString() ?? '',
      entityLabel: j['entityLabel']?.toString() ?? '',
      attributes: (j['attributes'] as List<dynamic>? ?? []).cast<String>(),
      lastN: int.tryParse(j['lastN']?.toString() ?? '10') ?? 10,
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
      lastN: lastN ?? this.lastN,
    );
  }
}
