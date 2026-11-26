import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';
import 'atender_pqr_screen.dart';

class AdminRadicadosScreen extends StatefulWidget {
  const AdminRadicadosScreen({super.key});

  @override
  State<AdminRadicadosScreen> createState() => _AdminRadicadosScreenState();
}

class _AdminRadicadosScreenState extends State<AdminRadicadosScreen> {
  static const _naranja = Color(0xFFF37003);
  static const _naranjaOscuro = Color(0xFFE04800);

  final _busqueda = TextEditingController();
  String _estado = 'All';
  int _pagina = 0;
  int _tamano = 5;
  int _totalPaginas = 1;
  int _total = 0;
  List _items = [];
  Map<String, Map<String, dynamic>> _prioridadesPorClave = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  int? _estadoAInt(String e) {
    switch (e) {
      case 'Abierto':
        return 0;
      case 'En Progreso':
        return 1;
      case 'Resuelto':
        return 2;
      case 'Cerrado':
        return 3;
      default:
        return null;
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultados = await Future.wait([
      ApiService.obtenerRadicadosAdmin(
        searchTerm: _busqueda.text.trim(),
        status: _estadoAInt(_estado),
        page: _pagina,
        size: _tamano,
      ),
      ApiService.obtenerPqrsPriorizadas(),
    ]);

    if (!mounted) return;

    final r = resultados[0] as Map<String, dynamic>?;
    final prios = resultados[1] as List;

    final mapaPrio = <String, Map<String, dynamic>>{};
    for (final p in prios) {
      if (p is Map) {
        final m = Map<String, dynamic>.from(p);
        final id = (m['id'] ?? m['complaintId'] ?? '').toString();
        final ref = (m['reference'] ?? '').toString();
        if (id.isNotEmpty) mapaPrio[id] = m;
        if (ref.isNotEmpty) mapaPrio[ref] = m;
      }
    }

    setState(() {
      _prioridadesPorClave = mapaPrio;
      if (r == null) {
        _error = 'No se pudieron cargar los radicados. Verifica tu conexión o sesión de administrador.';
      } else {
        _items = r['items'] as List;
        _total = r['total'] as int;
        _totalPaginas = (r['totalPages'] as int) < 1 ? 1 : r['totalPages'] as int;
      }
      _cargando = false;
    });
  }

  void _buscar() {
    _pagina = 0;
    _cargar();
  }

  void _irA(int p) {
    if (p < 0 || p >= _totalPaginas || p == _pagina) return;
    _pagina = p;
    _cargar();
  }

  Map _estilo(dynamic raw) {
    final s = (raw ?? '').toString().toUpperCase();
    final code = int.tryParse(s);
    if (code == 0 || s == 'PENDING' || s == 'OPEN') {
      return {'t': 'Abierto', 'bg': const Color(0xFFDBEAFE), 'fg': const Color(0xFF1D4ED8)};
    } else if (code == 1 || s == 'IN_PROGRESS') {
      return {'t': 'En Progreso', 'bg': const Color(0xFFFEF9C3), 'fg': const Color(0xFFA16207)};
    } else if (code == 2 || s == 'RESOLVED') {
      return {'t': 'Resuelto', 'bg': const Color(0xFFDCFCE7), 'fg': const Color(0xFF15803D)};
    } else if (code == 3 || s == 'CLOSED') {
      return {'t': 'Cerrado', 'bg': const Color(0xFFFEE2E2), 'fg': const Color(0xFFB91C1C)};
    }
    return {'t': 'Abierto', 'bg': const Color(0xFFDBEAFE), 'fg': const Color(0xFF1D4ED8)};
  }

  Map _tipo(dynamic raw) {
    switch (int.tryParse('$raw') ?? -1) {
      case 0:
        return {'t': 'Petición', 'c': const Color(0xFF2563EB)};
      case 1:
        return {'t': 'Queja', 'c': const Color(0xFFDC2626)};
      case 2:
        return {'t': 'Reclamo', 'c': const Color(0xFFEA580C)};
      case 3:
        return {'t': 'Sugerencia', 'c': const Color(0xFF16A34A)};
      case 4:
        return {'t': 'Felicitación', 'c': const Color(0xFF9333EA)};
      default:
        return {'t': 'Desconocido', 'c': const Color(0xFF4B5563)};
    }
  }

  Map _prediccion(dynamic raw) {
    switch ((raw ?? '').toString().trim()) {
      case 'MuyRapido':
        return {'t': 'Muy Rápido', 'i': Icons.arrow_circle_up_rounded, 'ic': const Color(0xFF16A34A), 'tc': const Color(0xFF15803D)};
      case 'Rapido':
        return {'t': 'Rápido', 'i': Icons.arrow_circle_down_rounded, 'ic': const Color(0xFF2563EB), 'tc': const Color(0xFF1D4ED8)};
      case 'Lento':
        return {'t': 'Lento', 'i': Icons.arrow_circle_down_rounded, 'ic': const Color(0xFFCA8A04), 'tc': const Color(0xFFA16207)};
      case 'MuyLento':
        return {'t': 'Muy Lento', 'i': Icons.arrow_circle_down_rounded, 'ic': const Color(0xFFDC2626), 'tc': const Color(0xFFB91C1C)};
      default:
        return {'t': 'Por Determinar', 'i': Icons.access_time_filled_rounded, 'ic': const Color(0xFF6B7280), 'tc': const Color(0xFF4B5563)};
    }
  }

 Map< String, dynamic > _infoPrioridad(Map c) {
    final id = (c['id'] ?? '').toString();
    final ref = (c['reference'] ?? '').toString();
    final extra = _prioridadesPorClave[id] ?? _prioridadesPorClave[ref] ?? {};

    final rawPrio = (c['predictedPriority'] ??
            extra['predictedPriority'] ??
            extra['priority'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    final rawConf = c['priorityConfidence'] ??
        extra['priorityConfidence'] ??
        extra['confidence'];

    int? pct;
    if (rawConf != null) {
      final val = double.tryParse(rawConf.toString());
      if (val != null) {
        pct = ((val > 0 && val <= 1.0) ? val * 100.0 : val).round();
      }
    }

    switch (rawPrio) {
      case 'ALTA':
        return {
          'label': 'ALTA',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFB91C1C),
          'pct': pct,
        };
      case 'BAJA':
        return {
          'label': 'BAJA',
          'bg': const Color(0xFFDCFCE7),
          'fg': const Color(0xFF15803D),
          'pct': pct,
        };
      case 'MEDIA':
        return {
          'label': 'MEDIA',
          'bg': const Color(0xFFFEF9C3),
          'fg': const Color(0xFFA16207),
          'pct': pct,
        };
      default:
        return {
          'label': 'Por Determinar',
          'bg': const Color(0xFFF1F5F9),
          'fg': const Color(0xFF475569),
          'pct': null,
        };
    }
  }

  String _fecha(dynamic raw) {
    if (raw == null) return 'Sin fecha';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      var h = d.hour;
      final p = h >= 12 ? 'PM' : 'AM';
      h = h % 12 == 0 ? 12 : h % 12;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, '
          '$h:${d.minute.toString().padLeft(2, '0')} $p';
    } catch (_) {
      return raw.toString();
    }
  }

  BoxDecoration _tarjeta() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      );

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155), width: 1.1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _naranja, width: 1.6)),
      );

  Widget _filtros() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Búsqueda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          TextField(controller: _busqueda, onSubmitted: (_) => _buscar(), decoration: _deco(hint: 'Asunto o radicado...')),
          const SizedBox(height: 18),
          const Text('Estado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _estado,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
            decoration: _deco(),
            items: ['All', 'Abierto', 'En Progreso', 'Resuelto', 'Cerrado']
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15))))
                .toList(),
            onChanged: (v) {
              setState(() => _estado = v ?? 'All');
              _buscar();
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _naranja,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _buscar,
            icon: const Icon(Icons.search, size: 22),
            label: const Text('Buscar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _fila(Map c) {
    final e = _estilo(c['status']);
    final t = _tipo(c['type']);
    final p = _prediccion(c['prediction']);
    final prio = _infoPrioridad(c);
    final id = (c['id'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_naranja, _naranjaOscuro],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RADICADO',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (c['reference'] ?? id).toString(),
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: e['bg'] as Color, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    e['t'] as String,
                    style: TextStyle(color: e['fg'] as Color, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASUNTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Text(
                  (c['subject'] ?? '').toString(),
                  style: const TextStyle(fontSize: 15.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('TIPO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(width: 11, height: 11, decoration: BoxDecoration(color: t['c'] as Color, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text(t['t'] as String, style: TextStyle(color: t['c'] as Color, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('TIEMPO ESTIMADO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(p['i'] as IconData, size: 18, color: p['ic'] as Color),
                    const SizedBox(width: 6),
                    Text(p['t'] as String, style: TextStyle(color: p['tc'] as Color, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('PRIORIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: prio['bg'] as Color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        prio['label'] as String,
                        style: TextStyle(
                          color: prio['fg'] as Color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (prio['pct'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${prio['pct']}%)',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Text('FECHA DE CREACIÓN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      _fecha(c['recievedDate'] ?? c['receivedDate']),
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _naranja,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: id.isEmpty
                        ? null
                        : () async {
                            final cambio = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => AtenderPqrScreen(id: id)),
                            );
                            if (cambio == true) _cargar();
                          },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Ver Detalles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultados() => Container(
        padding: const EdgeInsets.all(20),
        decoration: _tarjeta(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Resultados${!_cargando && _error == null ? ' ($_total)' : ''}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(children: [
                  CircularProgressIndicator(color: _naranja),
                  SizedBox(height: 12),
                  Text('Cargando…\n(el servidor puede tardar hasta 1 minuto en despertar)',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                ]),
              ),
            )
          else if (_error != null)
            Column(children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ])
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No se encontraron radicados.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          else
        ..._items.map((item) => _fila(Map< String, dynamic >.from(item as Map))),        ]),
      );

  static const double _bt = 40;
  static const double _gap = 4;

  Widget _btnPag(String t, {bool activo = false, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: _bt,
          height: _bt,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? _naranjaOscuro : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: activo ? _naranjaOscuro : const Color(0xFFE2E8F0)),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: activo
                      ? Colors.white
                      : (onTap == null ? const Color(0xFFCBD5E1) : const Color(0xFF334155)))),
        ),
      );

  Widget _paginacion() {
    return Column(children: [
      LayoutBuilder(builder: (context, c) {
        final caben = (c.maxWidth / (_bt + _gap)).floor();
        final numeros = (caben - 4).clamp(1, 7);
        final n = numeros > _totalPaginas ? _totalPaginas : numeros;
        var ini = _pagina - (n ~/ 2);
        if (ini < 0) ini = 0;
        var fin = ini + n - 1;
        if (fin >= _totalPaginas) {
          fin = _totalPaginas - 1;
          ini = (fin - n + 1) < 0 ? 0 : fin - n + 1;
        }
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final w in <Widget>[
            _btnPag('««', onTap: _pagina > 0 ? () => _irA(0) : null),
            _btnPag('«', onTap: _pagina > 0 ? () => _irA(_pagina - 1) : null),
            for (var i = ini; i <= fin; i++) _btnPag('${i + 1}', activo: i == _pagina, onTap: () => _irA(i)),
            _btnPag('»', onTap: _pagina < _totalPaginas - 1 ? () => _irA(_pagina + 1) : null),
            _btnPag('»»', onTap: _pagina < _totalPaginas - 1 ? () => _irA(_totalPaginas - 1) : null),
          ])
            Padding(padding: const EdgeInsets.symmetric(horizontal: _gap / 2), child: w),
        ]);
      }),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Elementos por página:', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: DropdownButton<int>(
            value: _tamano,
            underline: const SizedBox(),
            items: [5, 10, 20, 50].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
            onChanged: (v) {
              if (v == null) return;
              _tamano = v;
              _pagina = 0;
              _cargar();
            },
          ),
        ),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return QuejappNavbar(
      rutaActual: 'Radicados',
      child: RefreshIndicator(
        color: _naranja,
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _filtros(),
            const SizedBox(height: 18),
            _resultados(),
            const SizedBox(height: 18),
            if (!_cargando && _error == null) _paginacion(),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}