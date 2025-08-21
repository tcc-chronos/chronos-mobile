import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/device.dart';
import '../models/series_point.dart';
import '../services/fiware_api.dart';
import '../storage/settings_storage.dart';

class AppState extends ChangeNotifier {
  final _storage = SettingsStorage();
  final _api = FiwareApi();

  AppSettings _settings = AppSettings.defaults();
  AppSettings get settings => _settings;

  // Lista de devices para o dropdown (inicialmente só o selecionado)
  List<Device> _devices = [];
  List<Device> get devices => List.unmodifiable(_devices);

  // Dados dos gráficos por atributo (ex.: {"temperature": [...], "humidity":[...]})
  Map<String, List<SeriesPoint>> _series = {};
  Map<String, List<SeriesPoint>> get series => _series;

  bool _loadingSeries = false;
  bool get loadingSeries => _loadingSeries;

  bool _loadingDevices = false;
  bool get loadingDevices => _loadingDevices;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedSettings() async {
    _settings = await _storage.load();
    // dropdown inicia apenas com o selecionado (se existir)
    if (_settings.isConfigured) {
      _devices = [
        Device(
          deviceId: _settings.entityLabel.isNotEmpty
              ? _settings.entityLabel
              : _settings.entityId,
          entityName: _settings.entityId,
          entityType: _settings.entityType,
          attributes: _settings.attributes
              .map((a) => DeviceAttribute(name: a, type: 'Number'))
              .toList(),
        ),
      ];
    }
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings s) async {
    _settings = s;
    await _storage.save(_settings);
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    if (_settings.ip.isEmpty) {
      _errorMessage =
          'Informe o IP nas configurações antes de atualizar devices.';
      notifyListeners();
      return;
    }
    _loadingDevices = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _api.fetchDevices(_settings.ip);
      final mapByEntity = <String, Device>{
        for (final d in list) d.entityName: d,
      };
      _devices = mapByEntity.values.toList();
    } catch (e) {
      _errorMessage = 'Falha ao obter devices: $e';
    } finally {
      _loadingDevices = false;
      notifyListeners();
    }
  }

  Future<void> refreshSeries() async {
    if (!_settings.isConfigured) {
      _errorMessage =
          'Configure IP e selecione um device na aba Configurações.';
      notifyListeners();
      return;
    }
    if (_settings.attributes.isEmpty) {
      _errorMessage = 'O device selecionado não possui atributos.';
      notifyListeners();
      return;
    }

    _loadingSeries = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = <Future<void>>[];
      final map = <String, List<SeriesPoint>>{};

      for (final attr in _settings.attributes) {
        futures.add(
          _api
              .fetchAttributeSeries(
                ip: _settings.ip,
                entityType: _settings.entityType,
                entityId: _settings.entityId,
                attribute: attr,
                lastN: _settings.lastN,
              )
              .then((points) => map[attr] = points),
        );
      }

      await Future.wait(futures);
      _series = map;
    } catch (e) {
      _errorMessage = 'Falha ao atualizar dados: $e';
    } finally {
      _loadingSeries = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
