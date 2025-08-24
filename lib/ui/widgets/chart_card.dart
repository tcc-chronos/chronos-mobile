import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/series_point.dart';

class ChartCard extends StatelessWidget {
  final String attribute; // ex.: temperature
  final List<SeriesPoint> data; // pontos ordenados por tempo (crescente)
  final int? totalCount; // total vindo do header Fiware-Total-Count

  const ChartCard({
    super.key,
    required this.attribute,
    required this.data,
    this.totalCount,
  });

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _kpiChip(BuildContext context, String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formatações
    final axisDf = DateFormat('HH:mm\nMM-dd'); // rótulos do eixo X
    final tooltipDf = DateFormat('dd/MM/yyyy HH:mm:ss'); // tooltip
    final nfValue = NumberFormat('#,##0.##', 'pt_BR'); // valores Y
    final nfTotal = NumberFormat.decimalPattern('pt_BR'); // total com milhar

    final hasData = data.isNotEmpty;
    final lastValueStr = hasData ? nfValue.format(data.last.value) : '—';
    final totalStr = (totalCount != null) ? nfTotal.format(totalCount) : '—';
    final updatedStr = hasData
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(data.last.time.toLocal())
        : null;
    final title = _capitalize(attribute);

    if (!hasData) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Sem dados no intervalo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _kpiChip(context, 'Valor Atual', lastValueStr),
                  _kpiChip(context, 'Total', totalStr),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final xs = data
        .map((e) => e.time.millisecondsSinceEpoch.toDouble())
        .toList();
    final ys = data.map((e) => e.value).toList();

    // ranges com padding
    final rawMinX = xs.first, rawMaxX = xs.last;
    final rawMinY = ys.reduce((a, b) => a < b ? a : b);
    final rawMaxY = ys.reduce((a, b) => a > b ? a : b);
    final xRange = (rawMaxX - rawMinX).abs();
    final yRange = (rawMaxY - rawMinY).abs();
    final xPad = xRange == 0
        ? const Duration(minutes: 1).inMilliseconds.toDouble()
        : xRange * 0.05;
    final yPad = yRange == 0 ? (rawMaxY.abs() * 0.1 + 1) : yRange * 0.05;
    final minX = rawMinX - xPad, maxX = rawMaxX + xPad;
    final minY = rawMinY - yPad, maxY = rawMaxY + yPad;

    final xTick = (maxX - minX) / 4;
    final yTick = (maxY - minY) / 4;

    final spots = [
      for (final p in data)
        FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.value),
    ];

    bool isExtreme(double v, double lo, double hi) {
      final eps = (hi - lo).abs() * 0.001;
      return (v - lo).abs() <= eps || (v - hi).abs() <= eps;
    }

    String formatY(double v) => nfValue.format(v);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (updatedStr != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Atualizado em $updatedStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _kpiChip(context, 'Valor Atual', lastValueStr),
                _kpiChip(context, 'Total', totalStr),
              ],
            ),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border.fromBorderSide(BorderSide(width: .8)),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.all(4),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((barSpot) {
                          final yStr = formatY(barSpot.y);
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            barSpot.x.toInt(),
                            isUtc: true,
                          );
                          final when = tooltipDf.format(dt);
                          return LineTooltipItem(
                            '$yStr\n$when',
                            TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xTick,
                        getTitlesWidget: (value, meta) {
                          if (isExtreme(value, minX, maxX)) {
                            return const SizedBox.shrink();
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                            isUtc: true,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              axisDf.format(dt),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: yTick == 0 ? 1 : yTick,
                        getTitlesWidget: (value, meta) {
                          if (isExtreme(value, minY, maxY)) {
                            return const SizedBox.shrink();
                          }
                          return Text(formatY(value));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: false,
                      spots: spots,
                      barWidth: 2,
                      dotData: const FlDotData(
                        show: true,
                      ), // pontos nas medições
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
