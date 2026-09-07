import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../health_risk/domain/entities/health_risk_record.dart';
import '../../../../core/theme/senvo_theme.dart';

class RiskTimelineChart extends StatelessWidget {
  final List<HealthRiskRecord> riskHistory;

  const RiskTimelineChart({super.key, required this.riskHistory});

  @override
  Widget build(BuildContext context) {
    if (riskHistory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No historical data yet.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // Sort ascending by time for plotting
    final sortedHistory = List<HealthRiskRecord>.from(riskHistory)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Map to spots
    final spots = <FlSpot>[];
    double minX = sortedHistory.first.createdAt.millisecondsSinceEpoch.toDouble();
    double maxX = sortedHistory.last.createdAt.millisecondsSinceEpoch.toDouble();

    if (minX == maxX) {
      // If only one data point, add some padding
      minX -= const Duration(hours: 1).inMilliseconds;
      maxX += const Duration(hours: 1).inMilliseconds;
    }

    for (var record in sortedHistory) {
      spots.add(FlSpot(
        record.createdAt.millisecondsSinceEpoch.toDouble(),
        record.riskResult.overallScore,
      ));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Trend (Last 7 Days)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        // Only show title if it's the start, end, or middle (simplistic logic)
                        if (value == minX || value == maxX || spots.length < 5) {
                          return Text(
                            DateFormat('MM/dd HH:mm').format(date),
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: SenvoColors.accentBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: SenvoColors.accentBlue.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
