import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/device.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/validators.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ip;
  late TextEditingController _lastN;
  late TextEditingController _dateFrom;
  late TextEditingController _dateTo;
  QueryMode _mode = QueryMode.lastN;

  Device? _selectedDevice;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _ip = TextEditingController(text: settings.ip);
    _lastN = TextEditingController(text: settings.lastN.toString());
    _dateFrom = TextEditingController(text: settings.dateFromIso ?? '');
    _dateTo = TextEditingController(text: settings.dateToIso ?? '');
    _mode = settings.mode;

    // Seleciona o device atual (se existir na lista)
    final devices = context.read<AppState>().devices;
    if (settings.isConfigured) {
      _selectedDevice = devices.firstWhere(
        (d) => d.entityName == settings.entityId,
        orElse: () => Device(
          deviceId: settings.entityLabel.isNotEmpty
              ? settings.entityLabel
              : settings.entityId,
          entityName: settings.entityId,
          entityType: settings.entityType,
          attributes: settings.attributes
              .map((a) => DeviceAttribute(name: a, type: 'Number'))
              .toList(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ip.dispose();
    _lastN.dispose();
    _dateFrom.dispose();
    _dateTo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppState>();
    final current = app.settings;
    final device = _selectedDevice;

    final newSettings = current.copyWith(
      ip: _ip.text.trim(),
      entityId: device?.entityName ?? current.entityId,
      entityType: device?.entityType ?? current.entityType,
      entityLabel: device?.deviceId ?? current.entityLabel,
      attributes: device != null
          ? device.attributes.map((e) => e.name).toList()
          : current.attributes,
      mode: _mode,
      lastN: int.tryParse(_lastN.text.trim()) ?? current.lastN,
      dateFromIso: _dateFrom.text.trim().isEmpty ? null : _dateFrom.text.trim(),
      dateToIso: _dateTo.text.trim().isEmpty ? null : _dateTo.text.trim(),
    );

    await app.saveSettings(newSettings);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações salvas!')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        final devices = s.devices;

        return Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (s.errorMessage != null) ...[
                MaterialBanner(
                  content: Text(s.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: () => s.clearError(),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ip,
                      decoration: const InputDecoration(
                        labelText: 'IP do servidor FIWARE',
                        hintText: 'Ex.: 192.168.0.10',
                        prefixIcon: Icon(Icons.router_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.ip,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Device (IoT Agent)',
                              border: OutlineInputBorder(),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Device>(
                                isExpanded: true,
                                value: _selectedDevice,
                                hint: const Text('Selecione um device'),
                                items: devices.map((d) {
                                  final label =
                                      '${d.deviceId}  •  ${d.entityName}';
                                  return DropdownMenuItem<Device>(
                                    value: d,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (d) =>
                                    setState(() => _selectedDevice = d),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Atualizar devices do IoT Agent',
                          onPressed: s.loadingDevices
                              ? null
                              : () async {
                                  await s.refreshDevices();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (s.errorMessage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Devices atualizados'),
                                      ),
                                    );
                                  }
                                },
                          icon: s.loadingDevices
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Intervalo de coleta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<QueryMode>(
                      segments: const [
                        ButtonSegment<QueryMode>(
                          value: QueryMode.lastN,
                          label: Text('Últimos N'),
                          icon: Icon(Icons.format_list_numbered),
                        ),
                        ButtonSegment<QueryMode>(
                          value: QueryMode.dateRange,
                          label: Text('Intervalo de datas'),
                          icon: Icon(Icons.schedule),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (set) =>
                          setState(() => _mode = set.first),
                    ),

                    const SizedBox(height: 12),

                    // Campo N (usado tanto em lastN quanto em dateRange)
                    Row(
                      children: [
                        const Text('Limite (N)'),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _lastN,
                            decoration: const InputDecoration(
                              labelText: 'N (1–100)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: Validators.lastN,
                          ),
                        ),
                      ],
                    ),

                    // Campos de datas (visíveis somente no modo intervalo)
                    AnimatedCrossFade(
                      crossFadeState: _mode == QueryMode.dateRange
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 200),
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dateFrom,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'dateFrom (ex.: 2025-08-21T02:29:04.162Z)',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) => Validators.isoOrEmpty(v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _dateTo,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'dateTo (ex.: 2025-08-21T02:34:23.697Z)',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) => Validators.isoOrEmpty(v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Builder(
                              builder: (context) {
                                final msg = Validators.bothIsoRequired(
                                  _dateFrom.text,
                                  _dateTo.text,
                                );
                                return msg == null
                                    ? const SizedBox.shrink()
                                    : Text(
                                        msg,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar configurações'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Obs.: As requisições só ocorrem quando você clica em "Atualizar devices" ou "Atualizar dados". '
                      'Ao abrir o app, as configurações são restauradas, mas os gráficos precisam ser requisitados novamente.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
