import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../models/series_point.dart';

class FiwareApi {
  static const _service = 'smart';
  static const _servicePath = '/';
  final http.Client _client;
  final Duration timeout;

  FiwareApi({http.Client? client, this.timeout = const Duration(seconds: 12)})
    : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'fiware-service': _service,
    'fiware-servicepath': _servicePath,
  };

  /// GET http://{ip}:4041/iot/devices
  Future<List<Device>> fetchDevices(String ip) async {
    final uri = Uri.parse('http://$ip:4041/iot/devices');
    final res = await _client.get(uri, headers: _headers).timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Erro ao obter devices: HTTP ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (json['devices'] as List<dynamic>? ?? [])
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  /// GET http://{ip}:8666/STH/v1/contextEntities/type/{type}/id/{id}/attributes/{attr}?lastN=... [&dateFrom=...&dateTo=...]
  Future<List<SeriesPoint>> fetchAttributeSeries({
    required String ip,
    required String entityType,
    required String entityId,
    required String attribute,
    required int lastN,
    String? dateFromIso,
    String? dateToIso,
  }) async {
    final q = <String, String>{'lastN': lastN.toString()};
    if (dateFromIso != null && dateFromIso.isNotEmpty) {
      q['dateFrom'] = dateFromIso;
    }
    if (dateToIso != null && dateToIso.isNotEmpty) q['dateTo'] = dateToIso;

    final uri = Uri.http(
      '$ip:8666',
      '/STH/v1/contextEntities/type/$entityType/id/$entityId/attributes/$attribute',
      q,
    );

    final res = await _client.get(uri, headers: _headers).timeout(timeout);
    if (res.statusCode != 200) {
      throw Exception('Erro ao obter $attribute: HTTP ${res.statusCode}');
    }

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final responses = json['contextResponses'] as List<dynamic>?;

    if (responses == null || responses.isEmpty) {
      return <SeriesPoint>[];
    }

    final contextElement =
        (responses.first as Map<String, dynamic>)['contextElement']
            as Map<String, dynamic>?;

    final attributes = contextElement?['attributes'] as List<dynamic>? ?? [];
    if (attributes.isEmpty) return <SeriesPoint>[];

    final values =
        (attributes.first as Map<String, dynamic>)['values']
            as List<dynamic>? ??
        [];

    final points = <SeriesPoint>[];
    for (final v in values) {
      final m = v as Map<String, dynamic>;
      final recv = m['recvTime']?.toString();
      final raw = m['attrValue'];
      if (recv == null) continue;
      final dt = DateTime.tryParse(recv);
      final num? n = (raw is num) ? raw : num.tryParse(raw?.toString() ?? '');
      if (dt == null || n == null) continue;
      points.add(SeriesPoint(dt.toUtc(), n.toDouble()));
    }

    // ordenar por tempo crescente
    points.sort((a, b) => a.time.compareTo(b.time));
    return points;
  }

  void dispose() {
    _client.close();
  }
}
