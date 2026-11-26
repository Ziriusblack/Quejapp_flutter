import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';
import 'detalle_radicado_screen.dart';
import 'pqr_form_screen.dart';

class MisRadicadosScreen extends StatefulWidget {
  const MisRadicadosScreen({super.key});

  @override
  State<MisRadicadosScreen> createState() => _MisRadicadosScreenState();
}

class _MisRadicadosScreenState extends State<MisRadicadosScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  String _estadoSeleccionado = 'All';
  bool _isLoading = true;

  List _todasLasPqrs = [];
  List _pqrsFiltradas = [];
  int _totalResultados = 0;

  final Color naranjaPrincipal = const Color(0xFFF37003);
  final Color naranjaOscuro = const Color(0xFFE04800);

  @override
  void initState() {
    super.initState();
    _cargarPqrs();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  int? _mapearEstadoAEntero(String estadoTexto) {
    switch (estadoTexto) {
      case 'Abierto':
        return 0;
      case 'En Progreso':
        return 1;
      case 'Resuelto':
        return 2;
      case 'Cerrado':
        return 3;
      default:
        return null; // 'All' -> null
    }
  }

  Future<void> _cargarPqrs() async {
    setState(() => _isLoading = true);
    final term = _busquedaController.text.trim();
    final statusInt = _mapearEstadoAEntero(_estadoSeleccionado);

    final resultado = await ApiService.obtenerMisPqrs(
      searchTerm: term,
      status: statusInt,
    );

    if (mounted) {
      final items = resultado['items'] as List;
      final total = resultado['total'] as int;

      final bool isDefaultSearch = term.isEmpty && statusInt == null;
      if (total == 0 && isDefaultSearch) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PqrFormScreen()),
        );
        return;
      }

      setState(() {
        _todasLasPqrs = items;
        _pqrsFiltradas = items;
        _totalResultados = total;
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    _cargarPqrs();
  }

  // Exacto a classForStatus y labelForStatus de user-dashboard.ts
  Map _obtenerEstiloEstado(dynamic statusRaw) {
    final int code = int.tryParse(statusRaw?.toString() ?? '0') ?? 0;
    switch (code) {
      case 0:
        return {
          'texto': 'Abierto',
          'fondo': const Color(0xFFDBEAFE), // bg-blue-100
          'color': const Color(0xFF1D4ED8), // text-blue-700
        };
      case 1:
        return {
          'texto': 'En Progreso',
          'fondo': const Color(0xFFFEF9C3), // bg-yellow-100
          'color': const Color(0xFFA16207), // text-yellow-700
        };
      case 2:
        return {
          'texto': 'Resuelto',
          'fondo': const Color(0xFFDCFCE7), // bg-green-100
          'color': const Color(0xFF15803D), // text-green-700
        };
      case 3:
        return {
          'texto': 'Cerrado',
          'fondo': const Color(0xFFFEE2E2), // bg-red-100
          'color': const Color(0xFFB91C1C), // text-red-700
        };
      default:
        return {
          'texto': 'Desconocido',
          'fondo': const Color(0xFFF3F4F6),
          'color': const Color(0xFF374151),
        };
    }
  }

  // Exacto a classForType y showTypeName de user-dashboard.ts
  Map _obtenerEstiloTipo(dynamic typeRaw) {
    final int code = int.tryParse(typeRaw?.toString() ?? '0') ?? 0;
    switch (code) {
      case 0:
        return {'texto': 'Petición', 'color': const Color(0xFF2563EB)}; // text-blue-600
      case 1:
        return {'texto': 'Queja', 'color': const Color(0xFFDC2626)}; // text-red-600
      case 2:
        return {'texto': 'Reclamo', 'color': const Color(0xFFEA580C)}; // text-orange-600
      case 3:
        return {'texto': 'Sugerencia', 'color': const Color(0xFF16A34A)}; // text-green-600
      case 4:
        return {'texto': 'Felicitación', 'color': const Color(0xFF9333EA)}; // text-purple-600
      default:
        return {'texto': 'Desconocido', 'color': const Color(0xFF4B5563)};
    }
  }

  // Exacto a los @if / @else if de user-dashboard.html:
  // 'MuyRapido', 'Rapido', 'Lento', 'MuyLento'
  Map _obtenerEstiloPrediccion(dynamic predictionRaw) {
    final String pred = (predictionRaw ?? '').toString().trim();
    switch (pred) {
      case 'MuyRapido':
        return {
          'texto': 'Muy Rápido',
          'iconoColor': const Color(0xFF16A34A), // text-green-600
          'textoColor': const Color(0xFF15803D), // text-green-700
          'icono': Icons.arrow_circle_up_rounded,
        };
      case 'Rapido':
        return {
          'texto': 'Rápido',
          'iconoColor': const Color(0xFF2563EB), // text-blue-600
          'textoColor': const Color(0xFF1D4ED8), // text-blue-700
          'icono': Icons.arrow_circle_down_rounded,
        };
      case 'Lento':
        return {
          'texto': 'Lento',
          'iconoColor': const Color(0xFFCA8A04), // text-yellow-600
          'textoColor': const Color(0xFFA16207), // text-yellow-700
          'icono': Icons.arrow_circle_down_rounded,
        };
      case 'MuyLento':
        return {
          'texto': 'Muy Lento',
          'iconoColor': const Color(0xFFDC2626), // text-red-600
          'textoColor': const Color(0xFFB91C1C), // text-red-700
          'icono': Icons.arrow_circle_down_rounded,
        };
      default:
        return {
          'texto': 'Por Determinar',
          'iconoColor': const Color(0xFF6B7280), // text-gray-500
          'textoColor': const Color(0xFF4B5563), // text-gray-600
          'icono': Icons.access_time_filled_rounded,
        };
    }
  }

Map< String, dynamic > _obtenerEstiloPrioridad(Map< String, dynamic > pqr) {
    final rawPrio = (pqr['predictedPriority'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    final rawConf = pqr['priorityConfidence'];
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
          'texto': 'ALTA',
          'fondo': const Color(0xFFFEE2E2),
          'color': const Color(0xFFB91C1C),
          'borde': const Color(0xFFFECACA),
          'pct': pct,
        };
      case 'MEDIA':
        return {
          'texto': 'MEDIA',
          'fondo': const Color(0xFFFEF9C3),
          'color': const Color(0xFFA16207),
          'borde': const Color(0xFFFEF08A),
          'pct': pct,
        };
      case 'BAJA':
        return {
          'texto': 'BAJA',
          'fondo': const Color(0xFFDCFCE7),
          'color': const Color(0xFF15803D),
          'borde': const Color(0xFFBBF7D0),
          'pct': pct,
        };
      default:
        return {
          'texto': 'Por Determinar',
          'fondo': const Color(0xFFF1F5F9),
          'color': const Color(0xFF475569),
          'borde': const Color(0xFFCBD5E1),
          'pct': null,
        };
    }
  }

  String _formatearFecha(dynamic fechaRaw) {
    if (fechaRaw == null) return 'Sin fecha';
    try {
      final dt = DateTime.parse(fechaRaw.toString()).toLocal();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final anio = dt.year;
      int hora = dt.hour;
      final periodo = hora >= 12 ? 'PM' : 'AM';
      hora = hora % 12;
      if (hora == 0) hora = 12;
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$anio, $hora:$min $periodo';
    } catch (_) {
      return fechaRaw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuejappNavbar(
      rutaActual: 'Mis Radicados',
      child: RefreshIndicator(
        color: naranjaPrincipal,
        onRefresh: _cargarPqrs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buscar Quejas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Búsqueda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _busquedaController,
                      onSubmitted: (_) => _aplicarFiltros(),
                      decoration: InputDecoration(
                        hintText: 'Asunto o radicado...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                            width: 1.1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: naranjaPrincipal,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _estadoSeleccionado,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF475569),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                            width: 1.1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: naranjaPrincipal,
                            width: 1.6,
                          ),
                        ),
                      ),
                      items: ['All', 'Abierto', 'En Progreso', 'Resuelto', 'Cerrado']
                          .map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(
                            estado,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => _estadoSeleccionado = valor);
                          _aplicarFiltros();
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: naranjaPrincipal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _aplicarFiltros,
                      icon: const Icon(Icons.search_rounded, size: 22),
                      label: const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Resultados ($_totalResultados)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: naranjaPrincipal),
                  ),
                )
              else if (_pqrsFiltradas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'No se encontraron resultados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pqrsFiltradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final pqr = Map<String, dynamic>.from(
                      _pqrsFiltradas[index] as Map,
                    );
                    return _buildPqrCard(pqr);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPqrCard(Map<String, dynamic> pqr) {
    final radicado =
        (pqr['reference'] ?? pqr['id'] ?? 'SIN-RADICADO').toString();
    final asunto = (pqr['subject'] ?? 'Sin asunto').toString();
    final fecha = _formatearFecha(pqr['recievedDate']);

    final estiloEstado = _obtenerEstiloEstado(pqr['status']);
    final estiloTipo = _obtenerEstiloTipo(pqr['type']);
    final estiloPrediccion = _obtenerEstiloPrediccion(pqr['prediction']);
    final estiloPrioridad = _obtenerEstiloPrioridad(pqr);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [naranjaPrincipal, naranjaOscuro],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        radicado,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: estiloEstado['fondo'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estiloEstado['texto'] as String,
                    style: TextStyle(
                      color: estiloEstado['color'] as Color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ASUNTO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  asunto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'TIPO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: estiloTipo['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estiloTipo['texto'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: estiloTipo['color'] as Color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'TIEMPO ESTIMADO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      estiloPrediccion['icono'] as IconData,
                      color: estiloPrediccion['iconoColor'] as Color,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estiloPrediccion['texto'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: estiloPrediccion['textoColor'] as Color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

              const Text(
                  'PRIORIDAD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estiloPrioridad['fondo'] as Color,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: estiloPrioridad['borde'] as Color,
                        ),
                      ),
                      child: Text(
                        estiloPrioridad['texto'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: estiloPrioridad['color'] as Color,
                        ),
                      ),
                    ),
                    if (estiloPrioridad['pct'] != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${estiloPrioridad['pct']}%)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),


                const Text(
                  'FECHA DE CREACIÓN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fecha,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: naranjaPrincipal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleRadicadoScreen(pqrInicial: pqr),
                  ),
                );
                _cargarPqrs();
              },
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text(
                'Ver Detalles',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}