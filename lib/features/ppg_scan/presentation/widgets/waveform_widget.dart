import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  const WaveformWidget({required this.samples, super.key});
  final List<double> samples;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: LineChart(
      LineChartData(
        minY: -1,
        maxY: 1,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: samples.isEmpty
                ? const [FlSpot(0, 0)]
                : samples
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                      .toList(),
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            color: const Color(0xff63d7b0),
            belowBarData: BarAreaData(show: true, color: Color(0x2263d7b0)),
          ),
        ],
      ),
    ),
  );
}
