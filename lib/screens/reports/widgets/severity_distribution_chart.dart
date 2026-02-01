import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SeverityDistributionChart extends StatelessWidget {
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final int infoCount;

  const SeverityDistributionChart({
    Key? key,
    this.criticalCount = 3,
    this.highCount = 8,
    this.mediumCount = 15,
    this.lowCount = 24,
    this.infoCount = 47,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total =
        criticalCount + highCount + mediumCount + lowCount + infoCount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Severity Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Chart
          SizedBox(
            height: 200,
            child: total > 0
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _buildSections(),
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        touchCallback:
                            (FlTouchEvent event, pieTouchResponse) {},
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total =
        criticalCount + highCount + mediumCount + lowCount + infoCount;

    return [
      // Critical - Red
      PieChartSectionData(
        color: const Color(0xFFEF4444),
        value: criticalCount.toDouble(),
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // High - Orange
      PieChartSectionData(
        color: const Color(0xFFF97316),
        value: highCount.toDouble(),
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // Medium - Yellow/Amber
      PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: mediumCount.toDouble(),
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // Low - Blue
      PieChartSectionData(
        color: const Color(0xFF3B82F6),
        value: lowCount.toDouble(),
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // Info - Gray
      PieChartSectionData(
        color: const Color(0xFF64748B),
        value: infoCount.toDouble(),
        title: '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                'Critical',
                criticalCount,
                const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLegendItem(
                'High',
                highCount,
                const Color(0xFFF97316),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                'Medium',
                mediumCount,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLegendItem('Low', lowCount, const Color(0xFF3B82F6)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLegendItem(
                'Info',
                infoCount,
                const Color(0xFF64748B),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
