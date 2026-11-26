import 'package:flutter/material.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';
import 'atender_pqr_screen.dart';
import 'admin_extra_tabs.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _naranja = Color(0xFFF37003);
  static const _texto = Color(0xFF0F172A);
  static const _gris = Color(0xFF64748B);
  static const _gradNaranja = LinearGradient(colors: [Color(0xFFFFA800), Color(0xFFFF5E00)]);

  static const List<String> _nombresTipo = [
    'Petición',
    'Queja',
    'Reclamo',
    'Sugerencia',
    'Felicitación',
  ];

  static const List<String> _nombresCategoria = [
    'Servicio de Buses',
    'Tarifas y Pagos',
    'Horarios',
    'Rutas',
    'Infraestructura',
    'Atención al cliente',
    'Accesibilidad',
    'Seguridad',
    'Otros',
  ];

  DateTime? _desde, _hasta;
  int _tab = 0;
  bool _cargando = true;
  String? _error;
  AdminStats? _stats;
 List< Map< String, dynamic > > _prioridades = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _ver(DateTime? d) => d == null
      ? 'dd/mm/aaaa'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _prioridadResuelta(Map<String, dynamic> p) {
    final raw = (p['predictedPriority'] ?? p['priorityLevel'] ?? 'SIN EVALUAR')
        .toString()
        .trim()
        .toUpperCase();
    return raw.isEmpty ? 'SIN EVALUAR' : raw;
  }

  int _pesoPrioridad(String nivel) {
    switch (nivel) {
      case 'ALTA':
        return 3;
      case 'MEDIA':
        return 2;
      case 'BAJA':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final startStr = _desde == null ? null : _iso(_desde!);
    final endStr = _hasta == null ? null : _iso(_hasta!);

    final res = await Future.wait([
      ApiService.obtenerEstadisticasAdmin(startDate: startStr, endDate: endStr),
      ApiService.obtenerPqrsPriorizadas(startDate: startStr, endDate: endStr),
    ]);

    if (!mounted) return;

    final s = res[0];
    if (s is Map) {
      _stats = AdminStats.fromJson(Map<String, dynamic>.from(s));

      final lista = (res[1] as List)
          .whereType()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      lista.sort((a, b) {
        final pA = _pesoPrioridad(_prioridadResuelta(a));
        final pB = _pesoPrioridad(_prioridadResuelta(b));
        if (pB != pA) return pB.compareTo(pA);
        final scoreA = (a['priorityScore'] as num?)?.toInt() ?? 0;
        final scoreB = (b['priorityScore'] as num?)?.toInt() ?? 0;
        return scoreB.compareTo(scoreA);
      });

      _prioridades = lista;
    } else {
      _error = 'No se pudieron cargar las estadísticas. Verifica tu conexión o que tu sesión sea de administrador.';
    }
    setState(() => _cargando = false);
  }

  Future<void> _elegirFecha(bool esDesde) async {
    final f = await showDatePicker(
      context: context,
      initialDate: (esDesde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => esDesde ? _desde = f : _hasta = f);
  }

  // ---------- helpers visuales ----------
  BoxDecoration _tarjeta() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      );

  Widget _titulo(String emoji, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _texto)),
        ]),
      );

  Widget _gap([double h = 16]) => SizedBox(height: h);

  // ---------- secciones ----------
  Widget _filtros() {
    Widget campo(String label, DateTime? v, bool desde) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _elegirFecha(desde),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _ver(v),
                      style: TextStyle(color: v == null ? Colors.grey.shade500 : _texto, fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
                ]),
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          '📊 Dashboard de PQRS',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _texto, height: 1.15),
        ),
        _gap(20),
        campo('Desde:', _desde, true),
        _gap(12),
        campo('Hasta:', _hasta, false),
        _gap(16),
        Row(children: [
          InkWell(
            onTap: _cargar,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(gradient: _gradNaranja, borderRadius: BorderRadius.circular(10)),
              child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              setState(() {
                _desde = null;
                _hasta = null;
              });
              _cargar();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
              child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _tabs() {
    const nombres = ['Vista General', 'Por Empleado', 'Tendencias', 'Gráficos'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _tarjeta(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < nombres.length; i++)
            InkWell(
              onTap: () => setState(() => _tab = i),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _tab == i ? _gradNaranja : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  nombres[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _tab == i ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _kpi(String emoji, String label, int valor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: _tarjeta(),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
            Text('$valor', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _texto)),
          ]),
        ]),
      );

  Widget _alerta(String emoji, int n, String resto, Color fondo, Color borde, Color texto) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: borde, width: 4)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                TextSpan(text: ' $resto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              style: TextStyle(color: texto),
            ),
          ),
        ]),
      );

  Widget _tiempoResolucion(AdminStats s) {
    Widget col(String l, String v) => Expanded(
          child: Column(children: [
            Text(l, style: const TextStyle(fontSize: 12, color: _gris)),
            const SizedBox(height: 4),
            Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _texto)),
            const Text('días', style: TextStyle(fontSize: 12, color: _gris)),
          ]),
        );
    final sat = s.satisfaccion.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo('⏱️', 'Tiempo de Resolución'),
        Row(children: [
          col('Promedio', s.promedioDias.toStringAsFixed(1)),
          col('Mínimo', '${s.minDias}'),
          col('Máximo', '${s.maxDias}'),
        ]),
        const Divider(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Satisfacción', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Text('${sat.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
        ]),
        const SizedBox(height: 8),
        _barra(sat / 100, const Color(0xFF16A34A), alto: 10),
      ]),
    );
  }

  Widget _barra(double fraccion, Color color, {double alto = 16}) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(children: [
          Container(height: alto, color: const Color(0xFFE5E7EB)),
          FractionallySizedBox(
            widthFactor: fraccion.clamp(0.03, 1.0),
            child: Container(height: alto, color: color),
          ),
        ]),
      );

  Color _colorEstado(String n) {
    final k = n.toLowerCase();
    if (k.contains('radicad') || k.contains('nuev')) return const Color(0xFF2F80FF);
    if (k.contains('resuel')) return const Color(0xFF6B7280);
    if (k.contains('proceso')) return const Color(0xFFF97316);
    if (k.contains('cerrad')) return const Color(0xFF16A34A);
    return const Color(0xFF94A3B8);
  }

  Widget _porEstado(AdminStats s) {
    final total = s.total == 0 ? 1 : s.total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo('📊', 'Por Estado'),
        ...s.porEstado.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, color: _texto)),
                ]),
                const SizedBox(height: 6),
                _barra(e.value / total, _colorEstado(e.key)),
              ]),
            )),
      ]),
    );
  }

  List<Color> _gradTipo(String n) {
    final k = n.toLowerCase();
    if (k.contains('peti')) return const [Color(0xFF4F8DFF), Color(0xFF2563EB)];
    if (k.contains('suger')) return const [Color(0xFF22D36B), Color(0xFF00B84A)];
    if (k.contains('quej')) return const [Color(0xFFFF6B7A), Color(0xFFFF2D3F)];
    if (k.contains('felic')) return const [Color(0xFF9CA3AF), Color(0xFF6B7280)];
    if (k.contains('recla')) return const [Color(0xFFFF8A00), Color(0xFFFF5E00)];
    return const [Color(0xFF94A3B8), Color(0xFF64748B)];
  }

  Widget _porTipo(AdminStats s) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _titulo('🏷️', 'Por Tipo'),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: s.porTipo.entries
                  .map((e) => Container(
                        width: w,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _gradTipo(e.key),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            '${e.value}',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ]),
                      ))
                  .toList(),
            );
          }),
        ]),
      );

  Widget _porCategoria(AdminStats s) => Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _titulo('📁', 'Por Categoría'),
          ...s.porCategoria.entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border(left: BorderSide(color: Color(0xFFA855F7), width: 4)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF9333EA))),
                ]),
              )),
        ]),
      );

  // ---------- priorización (Red Neuronal TensorFlow) ----------
  Color _colorNivel(String nivel) {
    switch (nivel) {
      case 'ALTA':
        return const Color(0xFFDC2626);
      case 'MEDIA':
        return const Color(0xFFEAB308);
      case 'BAJA':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _etiquetaTipo(dynamic raw) {
    final idx = int.tryParse(raw?.toString() ?? '');
    if (idx != null && idx >= 0 && idx < _nombresTipo.length) {
      return _nombresTipo[idx];
    }
    final txt = (raw ?? '').toString().trim();
    return txt.isEmpty ? 'PQRS' : txt;
  }

  String _etiquetaCategoria(dynamic raw) {
    final idx = int.tryParse(raw?.toString() ?? '');
    if (idx != null && idx >= 0 && idx < _nombresCategoria.length) {
      return _nombresCategoria[idx];
    }
    final txt = (raw ?? '').toString().trim();
    return txt.isEmpty ? 'General' : txt;
  }

  Widget _priorizacion() {
    final criticas = _prioridades.where((p) => _prioridadResuelta(p) == 'ALTA').length;
    final top10 = _prioridades.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tarjeta(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Modelo de Priorización Inteligente (Red Neuronal)',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _texto),
        ),
        const SizedBox(height: 6),
        const Text(
          'PQRS clasificadas por Red Neuronal TensorFlow y ordenadas por criticidad y tiempo',
          style: TextStyle(color: _gris, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Mostrando top ${top10.length} de ${_prioridades.length}',
              style: const TextStyle(color: _gris, fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                '🔥 $criticas prioridad alta',
                style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        if (top10.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No hay solicitudes pendientes en el modelo de priorización.', style: TextStyle(color: _gris)),
          ),
        ...top10.map(_prioridadCard),
      ]),
    );
  }

  Widget _chip(String t, Color fondo, Color borde, Color texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borde),
        ),
        child: Text(t, style: TextStyle(color: texto, fontWeight: FontWeight.w800, fontSize: 12.5)),
      );

  Widget _prioridadCard(Map<String, dynamic> p) {
    final nivel = _prioridadResuelta(p);
    final c = _colorNivel(nivel);

    final idCompleto = (p['id'] ?? '').toString();
    final corto = idCompleto.length >= 8 ? idCompleto.substring(0, 8) : idCompleto;
    final ref = (p['radicado'] ?? p['reference'] ?? corto).toString();

    final subject = (p['subject'] ?? 'Sin asunto').toString();
    final detalle = (p['reason'] ?? p['description'] ?? '').toString();

    final double? confianza = (p['priorityConfidence'] as num?)?.toDouble();
    final int? score = (p['priorityScore'] as num?)?.toInt();
    final int? diasAbierta = (p['daysOpen'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: c),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                  Text(
                    '#$ref',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: _gris,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subject,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _texto),
                  ),
                ]),
                if (detalle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      nivel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                  if (confianza != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        '${(confianza * 100).toStringAsFixed(0)}% IA',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ]),
                const Divider(height: 24),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (score != null)
                    _chip(
                      'Score: $score',
                      const Color(0xFFFFF7ED),
                      const Color(0xFFFDBA74),
                      const Color(0xFFC2410C),
                    ),
                  _chip(
                    _etiquetaTipo(p['type']),
                    const Color(0xFFEFF6FF),
                    const Color(0xFFDBEAFE),
                    const Color(0xFF1D4ED8),
                  ),
                  _chip(
                    _etiquetaCategoria(p['category']),
                    const Color(0xFFFAF5FF),
                    const Color(0xFFF3E8FF),
                    const Color(0xFF7E22CE),
                  ),
                  if (diasAbierta != null)
                    _chip(
                      '⏱️ $diasAbierta días abierta',
                      diasAbierta >= 10 ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                      diasAbierta >= 10 ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
                      diasAbierta >= 10 ? const Color(0xFF991B1B) : const Color(0xFF374151),
                    ),
                ]),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final cambio = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => AtenderPqrScreen(id: idCompleto, rutaActual: 'Dashboard')),
                      );
                      if (cambio == true) _cargar();
                    },
                    child: const Text(
                      'Atender PQRS →',
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return QuejappNavbar(
      rutaActual: 'Dashboard',
      child: RefreshIndicator(
        color: _naranja,
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _filtros(),
            _gap(),
            _tabs(),
            _gap(),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  CircularProgressIndicator(color: _naranja),
                  SizedBox(height: 14),
                  Text(
                    'Cargando estadísticas…\n(el servidor puede tardar hasta 1 minuto en despertar)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _gris),
                  ),
                ]),
              )
            else if (_error != null || s == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _tarjeta(),
                child: Column(children: [
                  Text(_error ?? 'Sin datos', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                ]),
              )
            else if (_tab == 0) ...[
              _kpi('📋', 'Total PQRS', s.total),
              _gap(),
              _kpi('✅', 'Cerradas', s.cerradas),
              _gap(),
              _kpi('⏳', 'En Progreso', s.enProgreso),
              _gap(),
              _kpi('📂', 'Abiertas', s.abiertas),
              _gap(),
              if (s.vencidas > 0) ...[
                _alerta(
                  '⚠️',
                  s.vencidas,
                  'PQRS vencidas requieren atención urgente',
                  const Color(0xFFFEF2F2),
                  const Color(0xFFEF4444),
                  const Color(0xFF991B1B),
                ),
                _gap(),
              ],
              if (s.proximasAVencer > 0) ...[
                _alerta(
                  '⏰',
                  s.proximasAVencer,
                  'PQRS próximas a vencer (menos de 3 días)',
                  const Color(0xFFFFFBEB),
                  const Color(0xFFEAB308),
                  const Color(0xFF854D0E),
                ),
                _gap(),
              ],
              _tiempoResolucion(s),
              _gap(),
              _porEstado(s),
              _gap(),
              _porTipo(s),
              _gap(),
              _porCategoria(s),
              _gap(),
              _priorizacion(),
            ] else if (_tab == 1)
              EmpleadosTab(stats: s)
            else if (_tab == 2)
              TendenciasTab(stats: s)
            else
              GraficosTab(stats: s),
          ]),
        ),
      ),
    );
  }
}