import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PqrStatsChart extends StatelessWidget {
  final int quejas;
  final int reclamos;
  final int sugerencias;

  const PqrStatsChart({
    super.key,
    required this.quejas,
    required this.reclamos,
    required this.sugerencias,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.redAccent,
              value: quejas.toDouble(),
              title: 'Quejas ($quejas)',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: Colors.orangeAccent,
              value: reclamos.toDouble(),
              title: 'Reclamos ($reclamos)',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: Colors.blueAccent,
              value: sugerencias.toDouble(),
              title: 'Sugerencias ($sugerencias)',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}