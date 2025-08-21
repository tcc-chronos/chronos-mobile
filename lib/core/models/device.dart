class DeviceAttribute {
  final String name; // ex.: temperature, humidity
  final String type; // ex.: Number

  DeviceAttribute({required this.name, required this.type});

  factory DeviceAttribute.fromJson(Map<String, dynamic> j) {
    return DeviceAttribute(
      name: j['name']?.toString() ?? '',
      type: j['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'type': type};
}

class Device {
  final String deviceId;
  final String entityName; // ex.: urn:ngsi-ld:Chronos:ESP32:001
  final String entityType; // ex.: Sensor
  final List<DeviceAttribute> attributes;

  Device({
    required this.deviceId,
    required this.entityName,
    required this.entityType,
    required this.attributes,
  });

  factory Device.fromJson(Map<String, dynamic> j) {
    final attrs = (j['attributes'] as List<dynamic>? ?? [])
        .map((a) => DeviceAttribute.fromJson(a as Map<String, dynamic>))
        .toList();

    return Device(
      deviceId: j['device_id']?.toString() ?? '',
      entityName: j['entity_name']?.toString() ?? '',
      entityType: j['entity_type']?.toString() ?? '',
      attributes: attrs,
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'entity_name': entityName,
    'entity_type': entityType,
    'attributes': attributes.map((e) => e.toJson()).toList(),
  };
}
