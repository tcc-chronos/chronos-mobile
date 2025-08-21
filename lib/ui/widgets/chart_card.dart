import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/series_point.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<SeriesPoint> data;

  const ChartCard({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final axisDf = DateFormat('HH:mm\nMM-dd'); // eixos
    final tooltipDf = DateFormat('dd/MM/yyyy HH:mm:ss'); // tooltip
    final nf = NumberFormat('##0.##');

    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Sem dados no intervalo.'),
        ),
      );
    }

    // X: milissegundos UTC
    final xs = data
        .map((e) => e.time.millisecondsSinceEpoch.toDouble())
        .toList();
    final ys = data.map((e) => e.value).toList();

    // Faixas brutas
    final rawMinX = xs.first;
    final rawMaxX = xs.last;
    final rawMinY = ys.reduce((a, b) => a < b ? a : b);
    final rawMaxY = ys.reduce((a, b) => a > b ? a : b);

    // Padding (5% do range) + fallbacks p/ ranges nulos
    final xRange = (rawMaxX - rawMinX).abs();
    final yRange = (rawMaxY - rawMinY).abs();

    final xPad = xRange == 0
        ? const Duration(minutes: 1).inMilliseconds.toDouble()
        : xRange * 0.05;
    final yPad = yRange == 0 ? (rawMaxY.abs() * 0.1 + 1) : yRange * 0.05;

    final minX = rawMinX - xPad;
    final maxX = rawMaxX + xPad;
    final minY = rawMinY - yPad;
    final maxY = rawMaxY + yPad;

    // Intervalos de marcação (4 divisões aproximadamente)
    final xTick = (maxX - minX) / 4;
    final yTick = (maxY - minY) / 4;

    final spots = [
      for (final p in data)
        FlSpot(p.time.millisecondsSinceEpoch.toDouble(), p.value),
    ];

    // Helper para esconder rótulos nos extremos (evita sobreposição)
    bool isExtreme(double v, double lo, double hi) {
      final eps = (hi - lo).abs() * 0.001;
      return (v - lo).abs() <= eps || (v - hi).abs() <= eps;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
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
                          final y = nf.format(barSpot.y);
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            barSpot.x.toInt(),
                            isUtc: true,
                          );
                          final when = tooltipDf.format(dt);
                          return LineTooltipItem(
                            '$y\n$when',
                            TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onInverseSurface,
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
                          return Text(nf.format(value));
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
                      dotData: const FlDotData(show: true),
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
