import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/empty_state.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, s, _) {
        final configured = s.settings.isConfigured;
        final title = configured
            ? 'Gráficos — ${s.settings.entityLabel.isNotEmpty ? s.settings.entityLabel : s.settings.entityId}'
            : 'Gráficos';

        final body = !configured
            ? EmptyState(
                title: 'Configure o servidor e um device',
                subtitle:
                    'Vá até a aba Configurações, informe o IP do FIWARE e selecione um device.',
                icon: Icons.settings_outlined,
              )
            : s.series.isEmpty
            ? EmptyState(
                title: 'Sem dados carregados',
                subtitle:
                    'Toque em "Atualizar dados" para buscar os últimos registros no STH-Comet.',
                icon: Icons.cloud_download_outlined,
                onAction: s.loadingSeries ? null : s.refreshSeries,
                actionLabel: s.loadingSeries
                    ? 'Atualizando...'
                    : 'Atualizar dados',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 8),
                  for (final attr in s.settings.attributes)
                    ChartCard(title: attr, data: s.series[attr] ?? const []),
                  const SizedBox(height: 48),
                ],
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            actions: [
              IconButton(
                tooltip: 'Atualizar dados',
                onPressed: s.loadingSeries ? null : s.refreshSeries,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: s.loadingSeries
                      ? const SizedBox(
                          key: ValueKey('spin'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, key: ValueKey('icon')),
                ),
              ),
            ],
          ),
          body: body,
          floatingActionButton: configured
              ? FloatingActionButton.extended(
                  onPressed: s.loadingSeries ? null : s.refreshSeries,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: s.loadingSeries
                        ? const SizedBox(
                            key: ValueKey('fabspin'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.cloud_download,
                            key: ValueKey('fabicon'),
                          ),
                  ),
                  label: Text(
                    s.loadingSeries ? 'Atualizando...' : 'Atualizar dados',
                  ),
                )
              : null,
        );
      },
    );
  }
}
