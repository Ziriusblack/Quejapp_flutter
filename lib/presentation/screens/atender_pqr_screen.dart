import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';

class AtenderPqrScreen extends StatefulWidget {
  final String id;
  final String rutaActual;
  const AtenderPqrScreen({super.key, required this.id, this.rutaActual = 'Radicados'});

  @override
  State<AtenderPqrScreen> createState() => _AtenderPqrScreenState();
}

class _AtenderPqrScreenState extends State<AtenderPqrScreen> {
  static const _naranja = Color(0xFFF37003);
  static const _naranjaTitulo = Color(0xFFFF6A00);

  static const _estados = {0: 'Pendiente', 1: 'En progreso', 2: 'Resuelta', 3: 'Cerrada'};
  static const _departamentos = [
    'Gerencia',
    'Secretaría General',
    'Dirección administrativa y financiera',
    'Oficina de asesoría jurídica',
    'Dirección de operaciones',
    'Dirección técnica',
    'Oficina de control interno',
    'Atención al ciudadano',
  ];
  static const _tipos = {0: 'Petición', 1: 'Queja', 2: 'Reclamo', 3: 'Sugerencia', 4: 'Felicitación'};
  static const Map<int, String> _categorias = {
    0: 'Servicio de Buses',
    1: 'Estaciones y Portales',
    2: 'Tarjetas y Recargas',
    3: 'Atención al Usuario',
    4: 'Seguridad',
    5: 'Otro',
  };

  final _resp = TextEditingController();
  Map<String, dynamic>? _pqr;
  int _status = 0;
  String _dep = '';
  bool _cargando = true, _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _resp.dispose();
    super.dispose();
  }

  int _parseStatus(dynamic raw) {
    final s = (raw ?? '0').toString().toUpperCase();
    final n = int.tryParse(s);
    if (n != null) return n.clamp(0, 3);
    if (s == 'IN_PROGRESS') return 1;
    if (s == 'RESOLVED') return 2;
    if (s == 'CLOSED') return 3;
    return 0;
  }

  Future<void> _cargar() async {
    final d = await ApiService.obtenerDetalleAdmin(widget.id);
    if (!mounted) return;
    setState(() {
      _pqr = d;
      if (d != null) {
        _status = _parseStatus(d['status']);
        final dep = (d['department'] ?? '').toString();
        _dep = _departamentos.contains(dep) ? dep : '';
        _resp.text = (d['response'] ?? '').toString();
      }
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (_status >= 2 && _resp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escribe una respuesta para resolver o cerrar el radicado.')));
      return;
    }
    setState(() => _guardando = true);
    final err = await ApiService.actualizarPqrAdmin(
      id: widget.id,
      status: _status,
      response: _resp.text.trim(),
      department: _dep,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (err == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Radicado actualizado'), backgroundColor: Color(0xFF16A34A)));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: const Color(0xFFDC2626)));
    }
  }

  String _fecha(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      var h = d.hour;
      final p = h >= 12 ? 'PM' : 'AM';
      h = h % 12 == 0 ? 12 : h % 12;
      return '${d.month}/${d.day}/${d.year % 100}, $h:${d.minute.toString().padLeft(2, '0')} $p';
    } catch (_) {
      return raw.toString();
    }
  }

  String _nombre(dynamic perfil, dynamic respaldo) {
    if (perfil is Map) {
      final n = '${perfil['name'] ?? ''} ${perfil['lastname'] ?? ''}'.trim();
      if (n.isNotEmpty) return n;
    }
    return (respaldo ?? '').toString();
  }

  String _correo(dynamic perfil, dynamic respaldo) =>
      (perfil is Map && perfil['email'] != null) ? perfil['email'].toString() : (respaldo ?? '').toString();

  String _categoria(dynamic raw) {
    final c = int.tryParse('$raw');
    if (c == null) return (raw ?? '').toString();
    return _categorias[c] ?? 'Categoría $c';
  }

  String _prediccionTexto(dynamic raw) {
    switch ((raw ?? '').toString().trim()) {
      case 'MuyRapido':
        return 'Muy Rápido';
      case 'Rapido':
        return 'Rápido';
      case 'Lento':
        return 'Lento';
      case 'MuyLento':
        return 'Muy Lento';
      default:
        return 'Por Determinar';
    }
  }

  Widget _datoPrioridad(Map<String, dynamic> p) {
  final rawPrio = (p['predictedPriority'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    final rawConf = p['priorityConfidence'];
    int? pct;
    if (rawConf != null) {
      final val = double.tryParse(rawConf.toString());
      if (val != null) {
        pct = ((val > 0 && val <= 1.0) ? val * 100.0 : val).round();
      }
    }

    Color bg = const Color(0xFFFEF9C3);
    Color fg = const Color(0xFFA16207);
    String label = 'MEDIA';
    if (rawPrio == 'ALTA' || rawPrio == 'HIGH' || rawPrio == '2') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      label = 'ALTA';
    } else if (rawPrio == 'BAJA' || rawPrio == 'LOW' || rawPrio == '0') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'BAJA';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Text(
            'Prioridad (IA): ',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
            child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12.5)),
          ),
          if (pct != null) ...[
            const SizedBox(width: 8),
            Text('($pct%)', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 15.5, height: 1.4, color: Color(0xFF1E293B)),
            children: [
              TextSpan(text: '$etiqueta ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              TextSpan(text: valor),
            ],
          ),
        ),
      );

  Widget _historial(Map<String, dynamic> p, String correoUsuario) {
    final lista = (p['traceability'] is List) ? List.from(p['traceability']) : [];
    final items = lista.whereType().toList();
    Widget linea(String fecha, String accion, String autor) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 9, right: 10, left: 4),
              child: Icon(Icons.circle, size: 6, color: Color(0xFF0F172A)),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF1E293B)),
                  children: [
                    TextSpan(text: '$fecha: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: '$accion realizado por $autor'),
                  ],
                ),
              ),
            ),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      const Text('Historial de Cambios',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFFEA4C0A))),
      const SizedBox(height: 12),
      if (items.isEmpty)
        linea(_fecha(p['recievedDate']), 'PQRS Radicada', correoUsuario)
      else
        for (final t in items)
          linea(_fecha(t['date']), (t['status'] ?? 'Actualización').toString(),
              (t['performedBy'] ?? correoUsuario).toString()),
    ]);
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _naranja, width: 1.6)),
      );

  Widget _etiqueta(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      );

  Widget _desplegable<T>({
    required T value,
    required List<MapEntry<T, String>> opciones,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        menuMaxHeight: 360,
        borderRadius: BorderRadius.circular(10),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
        decoration: _deco(),
        selectedItemBuilder: (_) => [
          for (final o in opciones)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(o.value,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A))),
            ),
        ],
        items: [
          for (final o in opciones)
            DropdownMenuItem<T>(
              value: o.key,
              child: Text(o.value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A))),
            ),
        ],
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    final p = _pqr;
    return QuejappNavbar(
      rutaActual: widget.rutaActual,
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _naranja))
          : p == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('No se pudo cargar el radicado'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: () {
                          setState(() => _cargando = true);
                          _cargar();
                        },
                        child: const Text('Reintentar')),
                  ]),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Gestionar Radicado',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _naranjaTitulo)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Detalles del Radicado',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          _dato('ID:', (p['reference'] ?? p['id'] ?? '').toString()),
                          _dato('Usuario:', _nombre(p['userProfile'], p['user'])),
                          _dato('Correo:', _correo(p['userProfile'], p['user'])),
                          _dato('Estado:', _estados[_parseStatus(p['status'])] ?? 'Pendiente'),
                          _dato('Tipo:', _tipos[int.tryParse('${p['type']}') ?? -1] ?? ''),
                          _dato('Categoría:', _categoria(p['category'])),
                          _datoPrioridad(p),
                          _dato('Tiempo Estimado (IA):', _prediccionTexto(p['prediction'])),
                          _dato('Asunto:', (p['subject'] ?? '').toString()),
                          _dato('Descripción:', (p['description'] ?? '').toString()),
                          _dato('Fecha Creación:', _fecha(p['recievedDate'])),
                          _dato('Última Actualización:', _fecha(p['updatedDate'])),
                          _historial(p, _correo(p['userProfile'], p['user'])),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _etiqueta('Estado'),
                          _desplegable<int>(
                            value: _status,
                            opciones: _estados.entries.toList(),
                            onChanged: (v) => setState(() => _status = v ?? _status),
                          ),
                          const SizedBox(height: 18),
                          _etiqueta('Dependencia'),
                          _desplegable<String>(
                            value: _dep,
                            opciones: [
                              const MapEntry('', 'Seleccione un departamento'),
                              for (final d in _departamentos) MapEntry(d, d),
                            ],
                            onChanged: (v) => setState(() => _dep = v ?? ''),
                          ),
                          const SizedBox(height: 18),
                          _etiqueta('Respuesta'),
                          TextField(
                            controller: _resp,
                            minLines: 4,
                            maxLines: 8,
                            decoration: _deco(hint: 'Escribe la respuesta del radicado...'),
                          ),
                          const SizedBox(height: 22),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _naranja,
                                side: const BorderSide(color: _naranja),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Volver', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _naranjaTitulo,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _guardando ? null : _guardar,
                              child: _guardando
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                ),
    );
  }
}