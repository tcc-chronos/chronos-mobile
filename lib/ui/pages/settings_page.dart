import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Device? _selectedDevice;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _ip = TextEditingController(text: settings.ip);
    _lastN = TextEditingController(text: settings.lastN.toString());

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
      lastN: int.tryParse(_lastN.text.trim()) ?? current.lastN,
    );

    await app.saveSettings(newSettings);

    if (!context.mounted) return;
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
          appBar: AppBar(
            title: Text(
              'Configurações',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _ip,
                              decoration: const InputDecoration(
                                labelText: 'IP do servidor FIWARE',
                                hintText: 'Ex.: 172.0.0.1',
                                prefixIcon: Icon(Icons.router_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: Validators.ip,
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                          final label = d.entityName;
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
                                const SizedBox(width: 16),
                                IconButton.filledTonal(
                                  tooltip: 'Atualizar devices do IoT Agent',
                                  onPressed: s.loadingDevices
                                      ? null
                                      : () async {
                                          await s.refreshDevices();
                                          if (!context.mounted) return;
                                          if (s.errorMessage == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Devices atualizados',
                                                ),
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
                            TextFormField(
                              controller: _lastN,
                              decoration: const InputDecoration(
                                labelText: 'Intervalo de coleta (1-100)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: Validators.lastN,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar configurações'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Obs.: As requisições só ocorrem quando você clica em "Atualizar devices" '
                    'ou "Atualizar dados". Ao abrir o app, as configurações são restauradas, '
                    'mas os gráficos precisam ser requisitados novamente.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
