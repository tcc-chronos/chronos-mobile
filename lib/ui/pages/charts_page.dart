import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../widgets/chart_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';

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
                    'Toque em "Atualizar dados" para buscar os últimos registros no STH‑Comet.',
                icon: Icons.cloud_download_outlined,
                onAction: s.loadingSeries ? null : s.refreshSeries,
                actionLabel: 'Atualizar dados',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 8),
                  for (final entry in s.series.entries)
                    ChartCard(title: entry.key, data: entry.value),
                  const SizedBox(height: 8),
                ],
              );

        return LoadingOverlay(
          visible: s.loadingSeries,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  tooltip: 'Atualizar dados',
                  onPressed: s.loadingSeries ? null : s.refreshSeries,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: body,
            floatingActionButton: configured
                ? FloatingActionButton.extended(
                    onPressed: s.loadingSeries ? null : s.refreshSeries,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Atualizar dados'),
                  )
                : null,
          ),
        );
      },
    );
  }
}
