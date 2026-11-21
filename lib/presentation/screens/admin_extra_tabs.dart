import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/models/admin_stats_model.dart';

const _texto = Color(0xFF0F172A);
const _gris = Color(0xFF64748B);
const _azul = Color(0xFF2563EB);
const _verde = Color(0xFF16A34A);
const _morado = Color(0xFF9333EA);
const _gradNaranja = LinearGradient(colors: [Color(0xFFFFA800), Color(0xFFFF5E00)]);

BoxDecoration _tarjeta() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
    );

Widget _encabezado(String emoji, String titulo, String sub) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(titulo,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _texto, height: 1.15)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(sub, style: const TextStyle(color: Color(0xFF475569), fontSize: 15)),
      ]),
    );

const _meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

// Convierte "2025-11" o "11/2025" en "Nov 2025". Si ya viene como texto, lo deja igual.
String etiquetaMes(String m) {
  final a = RegExp(r'^(\d{4})[-/](\d{1,2})').firstMatch(m);
  final b = RegExp(r'^(\d{1,2})[-/](\d{4})').firstMatch(m);
  int? mes, anio;
  if (a != null) {
    anio = int.parse(a.group(1)!);
    mes = int.parse(a.group(2)!);
  } else if (b != null) {
    mes = int.parse(b.group(1)!);
    anio = int.parse(b.group(2)!);
  }
  if (mes != null && mes >= 1 && mes <= 12) return '${_meses[mes - 1]} $anio';
  return m;
}

Color _colorTipo(String n) {
  final k = n.toLowerCase();
  if (k.contains('peti')) return const Color(0xFF2F80FF);
  if (k.contains('suger')) return const Color(0xFF10B981);
  if (k.contains('quej')) return const Color(0xFFFF4757);
  if (k.contains('felic')) return const Color(0xFF6B7280);
  if (k.contains('recla')) return const Color(0xFFFF7A00);
  return const Color(0xFF94A3B8);
}

Color _colorEstado(String n) {
  final k = n.toLowerCase();
  if (k.contains('radicad') || k.contains('nuev')) return const Color(0xFF2F80FF);
  if (k.contains('resuel')) return const Color(0xFF6B7280);
  if (k.contains('proceso')) return const Color(0xFFF97316);
  if (k.contains('cerrad')) return const Color(0xFF16A34A);
  return const Color(0xFF94A3B8);
}

/// Hace que un gráfico nunca se apriete: ocupa al menos [minWidth] y, si no cabe, se desliza.
Widget _scrollable(double minWidth, Widget chart, {double height = 260}) => LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth > minWidth ? c.maxWidth : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // El padding superior evita que se recorte la etiqueta del eje Y más alta
          child: Padding(
            padding: const EdgeInsets.only(top: 18, right: 10),
            child: SizedBox(width: w - 10, height: height, child: chart),
          ),
        );
      },
    );

Widget _leyenda(String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 26,
          height: 12,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99))),
      const SizedBox(width: 8),
      Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155))),
    ]);

Widget _tituloTarjeta(String emoji, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _texto))),
      ]),
    );

// =====================================================================
//  POR EMPLEADO
// =====================================================================
class EmpleadosTab extends StatelessWidget {
  final AdminStats stats;
  const EmpleadosTab({super.key, required this.stats});

  Widget _caja(String valor, String label, {bool destacada = false}) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: destacada ? const Color(0xFFF5F0FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: destacada ? Border.all(color: const Color(0xFFA855F7), width: 2) : null,
          ),
          child: Column(children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: destacada ? const Color(0xFF9D00D6) : _texto)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: destacada ? const Color(0xFF9D00D6) : const Color(0xFF334155))),
          ]),
        ),
      );

  Widget _tarjetaEmpleado(int rank, EmployeeStats e) {
    final pct = e.tasaResolucion.clamp(0, 100).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _tarjeta(),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              gradient: _gradNaranja,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
            ),
            child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 60),
              child: Text(e.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _texto)),
            ),
            const SizedBox(height: 4),
            Text(e.email, style: const TextStyle(color: _gris, fontSize: 14)),
            const SizedBox(height: 18),
            Row(children: [
              _caja('${e.asignadas}', 'Asignadas'),
              _caja('${e.resueltas}', 'Resueltas', destacada: true),
              _caja(e.tiempoPromedio.toStringAsFixed(1), 'Días\nProm.'),
            ]),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Stack(children: [
                Container(height: 12, color: const Color(0xFFE5E7EB)),
                FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.03, 1.0),
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF9D00FF), Color(0xFF4F46E5)])),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('${pct.toStringAsFixed(2)}% de efectividad',
                  style: const TextStyle(color: Color(0xFF9D00D6), fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = stats.empleados.take(10).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('👥', 'Rendimiento por Empleado', 'Top 10 empleados por PQRS resueltas'),
      const SizedBox(height: 16),
      if (lista.isEmpty)
        Container(
            padding: const EdgeInsets.all(20),
            decoration: _tarjeta(),
            child: const Text('Aún no hay PQRS atendidas por empleados.', style: TextStyle(color: _gris))),
      for (var i = 0; i < lista.length; i++) _tarjetaEmpleado(i + 1, lista[i]),
    ]);
  }
}

// =====================================================================
//  TENDENCIAS
// =====================================================================
class TendenciasTab extends StatelessWidget {
  final AdminStats stats;
  const TendenciasTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = stats.tendencias;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('📈', 'Tendencias Mensuales', 'Evolución de PQRS por mes'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: t.isEmpty
            ? const Text('No hay datos mensuales.', style: TextStyle(color: _gris))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 18, runSpacing: 8, children: [
                  _leyenda('Recibidas', _azul),
                  _leyenda('Resueltas', const Color(0xFF00B84A)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                  child: _scrollable(t.length * 84.0 + 50, _barras(t), height: 280),
                ),
              ]),
      ),
      const SizedBox(height: 16),
      if (t.isNotEmpty) _tabla(t),
    ]);
  }

  Widget _barras(List<MonthlyTrend> t) {
    final maxV = t.fold<int>(1, (m, e) => [m, e.recibidas, e.resueltas].reduce((a, b) => a > b ? a : b)).toDouble();
    return BarChart(BarChartData(
      maxY: maxV,
      minY: 0,
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: maxV / 2,
            getTitlesWidget: (v, m) => Text(v.round().toString(),
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w700)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              if (i < 0 || i >= t.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(etiquetaMes(t[i].month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < t.length; i++)
          BarChartGroupData(x: i, barsSpace: 6, barRods: [
            BarChartRodData(
                toY: t[i].recibidas.toDouble(),
                width: 16,
                color: const Color(0xFF2F80FF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
            BarChartRodData(
                toY: t[i].resueltas.toDouble(),
                width: 16,
                color: const Color(0xFF00B84A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          ]),
      ],
    ));
  }

  Widget _tabla(List<MonthlyTrend> t) {
    const anchos = [90.0, 100.0, 100.0, 110.0, 100.0];
    Widget celda(int i, Widget w) => SizedBox(width: anchos[i], child: w);
    Text cab(String s) =>
        Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: .4));

    Widget badge(double pct) {
      Color fondo, txt;
      if (pct >= 80) {
        fondo = const Color(0xFFD1FAE5);
        txt = const Color(0xFF065F46);
      } else if (pct >= 50) {
        fondo = const Color(0xFFFEF3C7);
        txt = const Color(0xFF92400E);
      } else {
        fondo = const Color(0xFFFEE2E2);
        txt = const Color(0xFFB91C1C);
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(99)),
          child: Text('${pct.round()}%', style: TextStyle(color: txt, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      );
    }

    return Container(
      decoration: _tarjeta(),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(children: [
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              celda(0, cab('MES')), celda(1, cab('RECIBIDAS')), celda(2, cab('RESUELTAS')),
              celda(3, cab('TIEMPO PROM.')), celda(4, cab('EFICIENCIA')),
            ]),
          ),
          for (final m in t)
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(children: [
                celda(0, Text(etiquetaMes(m.month), style: const TextStyle(fontWeight: FontWeight.w800, color: _texto))),
                celda(1, Text('${m.recibidas}', style: const TextStyle(color: Color(0xFF475569)))),
                celda(2, Text('${m.resueltas}', style: const TextStyle(color: Color(0xFF475569)))),
                celda(3, Text('${m.tiempoPromedio.toStringAsFixed(1)} días', style: const TextStyle(color: Color(0xFF475569)))),
                celda(4, badge(m.eficiencia)),
              ]),
            ),
        ]),
      ),
    );
  }
}

// =====================================================================
//  GRÁFICOS (reemplaza Power BI)
// =====================================================================
class GraficosTab extends StatelessWidget {
  final AdminStats stats;
  const GraficosTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('📊', 'Gráficos Estadísticos', 'Visualización de indicadores y métricas PQRS'),
      const SizedBox(height: 16),
      _tarjetaDona(),
      const SizedBox(height: 16),
      _tarjetaTipos(),
      const SizedBox(height: 16),
      _tarjetaLineas(),
      const SizedBox(height: 16),
      _tarjetaIndicadores(),
      const SizedBox(height: 22),
      const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text('Análisis avanzado',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texto)),
      ),
      const SizedBox(height: 14),
      _tarjetaApiladas(),
      const SizedBox(height: 16),
      _tarjetaEficiencia(),
      const SizedBox(height: 16),
      if (stats.porTipo.length >= 3) ...[_tarjetaRadar(), const SizedBox(height: 16)],
      _tarjetaMedidor(),
      const SizedBox(height: 16),
      _tarjetaEmpleados(),
    ]);
  }

  // 1. Donut por estado
  Widget _tarjetaDona() {
    final e = stats.porEstado.entries.where((x) => x.value > 0).toList();
    final total = e.fold<int>(0, (a, b) => a + b.value);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('🥧', 'Distribución por Estado'),
        if (total == 0)
          const Text('Sin datos', style: TextStyle(color: _gris))
        else ...[
          SizedBox(
            height: 220,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 64,
                sections: [
                  for (final x in e)
                    PieChartSectionData(value: x.value.toDouble(), color: _colorEstado(x.key), radius: 34, showTitle: false),
                ],
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$total', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _texto)),
                const Text('Total', style: TextStyle(color: _gris, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          for (final x in e)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _colorEstado(x.key), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(x.key, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                Text('${x.value}', style: const TextStyle(fontWeight: FontWeight.w800, color: _texto)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Text('${(x.value / total * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.right, style: const TextStyle(color: _gris, fontSize: 12)),
                ),
              ]),
            ),
        ],
      ]),
    );
  }

  // 2. Barras por tipo
  Widget _tarjetaTipos() {
    final e = stats.porTipo.entries.toList();
    final maxV = e.fold<int>(1, (m, x) => x.value > m ? x.value : m).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('🏷️', 'PQRS por Tipo'),
        if (e.isEmpty)
          const Text('Sin datos', style: TextStyle(color: _gris))
        else
          _scrollable(
            e.length * 76.0 + 40,
            BarChart(BarChartData(
              maxY: maxV * 1.15,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, m) => Text(v.round().toString(),
                        style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w700)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= e.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(e[i].key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < e.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: e[i].value.toDouble(),
                      width: 26,
                      color: _colorTipo(e[i].key),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ]),
              ],
            )),
          ),
      ]),
    );
  }

  // 3. Líneas: evolución mensual
  Widget _tarjetaLineas() {
    final t = stats.tendencias;
    final maxV = t.fold<int>(1, (m, e) => [m, e.recibidas, e.resueltas].reduce((a, b) => a > b ? a : b)).toDouble();
    LineChartBarData linea(List<double> ys, Color c) => LineChartBarData(
          spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
          isCurved: true,
          curveSmoothness: .25,
          preventCurveOverShooting: true,
          color: c,
          barWidth: 3.5,
          dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) =>
                  FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 3, strokeColor: c)),
          belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.10)),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('📈', 'Evolución Mensual'),
        if (t.isEmpty)
          const Text('Sin datos', style: TextStyle(color: _gris))
        else ...[
          Wrap(spacing: 18, runSpacing: 8, children: [
            _leyenda('Recibidas', const Color(0xFF2F80FF)),
            _leyenda('Resueltas', const Color(0xFF00B84A)),
          ]),
          const SizedBox(height: 16),
          _scrollable(
            t.length * 84.0 + 50,
            LineChart(LineChartData(
              minY: 0,
              maxY: maxV * 1.1,
              minX: -0.3,
              maxX: t.length - 0.7,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, m) => Text(v.round().toString(),
                        style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w700)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 1,
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (v != i.toDouble() || i < 0 || i >= t.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(etiquetaMes(t[i].month),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                linea(t.map((e) => e.recibidas.toDouble()).toList(), const Color(0xFF2F80FF)),
                linea(t.map((e) => e.resueltas.toDouble()).toList(), const Color(0xFF00B84A)),
              ],
            )),
          ),
        ],
      ]),
    );
  }

  // 4. Indicadores circulares
  Widget _anillo(String titulo, double pct, Color color) {
    final v = pct.clamp(0, 100).toDouble();
    return Expanded(
      child: Column(children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(value: v == 0 ? 0.0001 : v, color: color, radius: 14, showTitle: false),
                PieChartSectionData(value: 100 - v, color: const Color(0xFFE5E7EB), radius: 14, showTitle: false),
              ],
            )),
            Text('${v.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _texto)),
          ]),
        ),
        const SizedBox(height: 8),
        Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155), fontSize: 13)),
      ]),
    );
  }

  Widget _tarjetaIndicadores() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _tituloTarjeta('🎯', 'Indicadores Clave'),
          Row(children: [
            _anillo('Tasa de resolución', stats.tasaResolucion, _morado),
            _anillo('Satisfacción', stats.satisfaccion, _verde),
          ]),
        ]),
      );

  // ---------------- AVANZADOS ----------------

  FlTitlesData _ejes({required List<String> etiquetasX, String sufijoY = '', double? intervaloY}) => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: intervaloY,
            getTitlesWidget: (v, m) => Text('${v.round()}$sufijoY',
                style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w700)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 1,
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              if (v != i.toDouble() || i < 0 || i >= etiquetasX.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(etiquetasX[i],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              );
            },
          ),
        ),
      );

  FlGridData get _rejilla => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1));

  Widget _sinDatos() => const Text('Sin datos', style: TextStyle(color: _gris));

  // A) Barras apiladas: resueltas + sin resolver = recibidas
  Widget _tarjetaApiladas() {
    final t = stats.tendencias;
    final maxV = t.fold<int>(1, (m, e) => e.recibidas > m ? e.recibidas : m).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('🧱', 'Resueltas vs. Sin resolver'),
        if (t.isEmpty)
          _sinDatos()
        else ...[
          Wrap(spacing: 18, runSpacing: 8, children: [
            _leyenda('Resueltas', const Color(0xFF00B84A)),
            _leyenda('Sin resolver', const Color(0xFFFF8A00)),
          ]),
          const SizedBox(height: 16),
          _scrollable(
            t.length * 84.0 + 50,
            BarChart(BarChartData(
              maxY: maxV * 1.1,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: _rejilla,
              borderData: FlBorderData(show: false),
              titlesData: _ejes(etiquetasX: t.map((e) => etiquetaMes(e.month)).toList()),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final m = t[group.x];
                    return BarTooltipItem(
                      '${etiquetaMes(m.month)}\nResueltas: ${m.resueltas}\nSin resolver: ${m.recibidas - m.resueltas}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < t.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: t[i].recibidas.toDouble(),
                      width: 30,
                      color: const Color(0xFFFF8A00),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      rodStackItems: [
                        BarChartRodStackItem(0, t[i].resueltas.toDouble(), const Color(0xFF00B84A)),
                        BarChartRodStackItem(t[i].resueltas.toDouble(), t[i].recibidas.toDouble(), const Color(0xFFFF8A00)),
                      ],
                    ),
                  ]),
              ],
            )),
            height: 280,
          ),
        ],
      ]),
    );
  }

  // B) Línea de eficiencia mensual con meta del 80 %
  Widget _tarjetaEficiencia() {
    final t = stats.tendencias;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('🎯', 'Eficiencia Mensual'),
        const Text('% de PQRS resueltas sobre las recibidas cada mes',
            style: TextStyle(color: _gris, fontSize: 13)),
        const SizedBox(height: 16),
        if (t.isEmpty)
          _sinDatos()
        else
          _scrollable(
            t.length * 84.0 + 50,
            LineChart(LineChartData(
              minY: 0,
              maxY: 100,
              minX: -0.3,
              maxX: t.length - 0.7,
              gridData: _rejilla,
              borderData: FlBorderData(show: false),
              titlesData: _ejes(
                  etiquetasX: t.map((e) => etiquetaMes(e.month)).toList(), sufijoY: '%', intervaloY: 25),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: 80,
                  color: const Color(0xFF16A34A),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => 'Meta 80%',
                    style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ]),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem('${s.y.toStringAsFixed(0)}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < t.length; i++) FlSpot(i.toDouble(), t[i].eficiencia.clamp(0, 100).toDouble())],
                  isCurved: true,
                  curveSmoothness: .25,
                  preventCurveOverShooting: true,
                  barWidth: 4,
                  gradient: const LinearGradient(colors: [Color(0xFF9D00FF), Color(0xFF4F46E5)]),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 5, color: Colors.white, strokeWidth: 3, strokeColor: const Color(0xFF7C3AED)),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFF9D00FF).withValues(alpha: 0.28), const Color(0xFF9D00FF).withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ],
            )),
            height: 260,
          ),
      ]),
    );
  }

  // C) Radar: perfil de PQRS por tipo
  Widget _tarjetaRadar() {
    final e = stats.porTipo.entries.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('🕸️', 'Perfil por Tipo de PQRS'),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: RadarChart(RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 1),
              tickBorderData: const BorderSide(color: Color(0xFFE5E7EB)),
              gridBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
              radarBorderData: const BorderSide(color: Color(0xFFCBD5E1)),
              titlePositionPercentageOffset: 0.16,
              titleTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              getTitle: (i, angle) => RadarChartTitle(text: '${e[i].key}\n${e[i].value}', angle: 0),
              dataSets: [
                RadarDataSet(
                  fillColor: const Color(0xFFF37003).withValues(alpha: 0.25),
                  borderColor: const Color(0xFFF37003),
                  borderWidth: 2.5,
                  entryRadius: 4,
                  dataEntries: [for (final x in e) RadarEntry(value: x.value.toDouble())],
                ),
              ],
            )),
          ),
        ),
      ]),
    );
  }

  // D) Medidor semicircular: PQRS vencidas sobre el total
  Widget _tarjetaMedidor() {
    final total = stats.total == 0 ? 1 : stats.total;
    final pct = (stats.vencidas / total * 100).clamp(0, 100).toDouble();
    final color = pct >= 50 ? const Color(0xFFDC2626) : (pct >= 20 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('⏰', 'Medidor de Vencimientos'),
        Center(
          child: SizedBox(
            width: 260,
            height: 140,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              // OverflowBox deja que el círculo mida 260x260 aunque el área visible sea de 140 de alto
              ClipRect(
                child: SizedBox(
                  width: 260,
                  height: 140,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: 260,
                    maxWidth: 260,
                    minHeight: 260,
                    maxHeight: 260,
                    child: PieChart(PieChartData(
                      startDegreeOffset: 180,
                      sectionsSpace: 0,
                      centerSpaceRadius: 82,
                      sections: [
                        PieChartSectionData(value: pct == 0 ? 0.0001 : pct, color: color, radius: 26, showTitle: false),
                        PieChartSectionData(value: 100 - pct, color: const Color(0xFFE5E7EB), radius: 26, showTitle: false),
                        PieChartSectionData(value: 100, color: Colors.transparent, radius: 26, showTitle: false),
                      ],
                    )),
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
                const Text('vencidas', style: TextStyle(color: _gris, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _dato('Vencidas', '${stats.vencidas}', const Color(0xFFDC2626))),
          Expanded(child: _dato('Próximas a vencer', '${stats.proximasAVencer}', const Color(0xFFF59E0B))),
          Expanded(child: _dato('Total', '${stats.total}', _texto)),
        ]),
      ]),
    );
  }

  Widget _dato(String l, String v, Color c) => Column(children: [
        Text(v, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _gris, fontWeight: FontWeight.w600)),
      ]);

  // E) Barras agrupadas por empleado: asignadas vs. resueltas
  Widget _tarjetaEmpleados() {
    final e = stats.empleados.take(5).toList();
    final maxV = e.fold<int>(1, (m, x) => x.asignadas > m ? x.asignadas : m).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tituloTarjeta('👥', 'Carga vs. Resolución por Empleado'),
        if (e.isEmpty)
          _sinDatos()
        else ...[
          Wrap(spacing: 18, runSpacing: 8, children: [
            _leyenda('Asignadas', const Color(0xFF6366F1)),
            _leyenda('Resueltas', const Color(0xFF00B84A)),
          ]),
          const SizedBox(height: 16),
          _scrollable(
            e.length * 90.0 + 50,
            BarChart(BarChartData(
              maxY: maxV * 1.15,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: _rejilla,
              borderData: FlBorderData(show: false),
              titlesData: _ejes(etiquetasX: [for (var i = 0; i < e.length; i++) '#${i + 1}\n${e[i].nombre.split(' ').first}']),
              barGroups: [
                for (var i = 0; i < e.length; i++)
                  BarChartGroupData(x: i, barsSpace: 6, barRods: [
                    BarChartRodData(
                        toY: e[i].asignadas.toDouble(),
                        width: 18,
                        color: const Color(0xFF6366F1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                    BarChartRodData(
                        toY: e[i].resueltas.toDouble(),
                        width: 18,
                        color: const Color(0xFF00B84A),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                  ]),
              ],
            )),
            height: 260,
          ),
        ],
      ]),
    );
  }
}
