import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';

class DetalleRadicadoScreen extends StatefulWidget {
  final Map<String, dynamic> pqrInicial;

  const DetalleRadicadoScreen({
    super.key,
    required this.pqrInicial,
  });

  @override
  State<DetalleRadicadoScreen> createState() => _DetalleRadicadoScreenState();
}

class _DetalleRadicadoScreenState extends State<DetalleRadicadoScreen> {
  late Map<String, dynamic> _pqr;
  bool _isLoading = false;
  Map<String, dynamic>? _prediccionIa;

  final Color naranjaPrincipal = const Color(0xFFF37003);

  @override
  void initState() {
    super.initState();
    _pqr = Map<String, dynamic>.from(widget.pqrInicial);
    _cargarPrediccionSiFalta();
    _refrescarDetalleEnTiempoReal();
  }

  Future<void> _refrescarDetalleEnTiempoReal() async {
    final id = (_pqr['id'] ?? '').toString();
    if (id.isEmpty) return;

    setState(() => _isLoading = true);
    final detalleActualizado = await ApiService.obtenerDetallePqr(id);
    if (mounted) {
      setState(() {
        if (detalleActualizado != null && detalleActualizado is Map) {
          _pqr = Map<String, dynamic>.from(detalleActualizado);
        }
        _isLoading = false;
      });
      await _cargarPrediccionSiFalta();
    }
  }

  Future<void> _cargarPrediccionSiFalta() async {
    final probsExistentes = _pqr['probabilities'] ?? _pqr['probabilidades'];
    if (probsExistentes is Map && probsExistentes.isNotEmpty) return;

    final res = await ApiService.predecirTiempoPqr(
      type: int.tryParse('${_pqr['type']}') ?? 0,
      category: int.tryParse('${_pqr['category']}') ?? 0,
      subject: (_pqr['subject'] ?? '').toString(),
      description: (_pqr['description'] ?? '').toString(),
    );

    if (mounted && res is Map) {
      setState(() {
        _prediccionIa = Map<String, dynamic>.from(res);
      });
    }
  }

  String _obtenerTextoEstado(dynamic statusRaw) {
    if (statusRaw == null) return 'Pendiente';
    final int? code = int.tryParse(statusRaw.toString());
    if (code != null) {
      switch (code) {
        case 0:
          return 'Pendiente';
        case 1:
          return 'En Proceso';
        case 2:
          return 'Resuelta';
        default:
          return 'Cerrada';
      }
    }
    return statusRaw.toString();
  }

  String _obtenerTextoTipo(dynamic typeRaw) {
    if (typeRaw == null) return 'Petición';
    final int? code = int.tryParse(typeRaw.toString());
    if (code != null) {
      switch (code) {
        case 0:
          return 'Petición';
        case 1:
          return 'Queja';
        case 2:
          return 'Reclamo';
        case 3:
          return 'Sugerencia';
        case 4:
          return 'Felicitación';
        default:
          return 'Petición';
      }
    }
    return typeRaw.toString();
  }

  String _obtenerTextoCategoria(dynamic catRaw) {
    if (catRaw == null) return 'Servicio de Buses';
    final int? code = int.tryParse(catRaw.toString());
    if (code != null) {
      switch (code) {
        case 0:
          return 'Servicio de Buses';
        case 1:
          return 'Estaciones y Portales';
        case 2:
          return 'Tarjetas y Recargas';
        case 3:
          return 'Atención al Usuario';
        case 4:
          return 'Seguridad';
        default:
          return 'Otro';
      }
    }
    return catRaw.toString();
  }

  String _formatearFechaCorta(dynamic fechaRaw) {
    if (fechaRaw == null) return '';
    try {
      final dt = DateTime.parse(fechaRaw.toString()).toLocal();
      final mes = dt.month;
      final dia = dt.day;
      final anioCorto = dt.year.toString().substring(2);
      int hora = dt.hour;
      final periodo = hora >= 12 ? 'PM' : 'AM';
      hora = hora % 12;
      if (hora == 0) hora = 12;
      final min = dt.minute.toString().padLeft(2, '0');
      return '$mes/$dia/$anioCorto, $hora:$min $periodo';
    } catch (_) {
      return fechaRaw.toString();
    }
  }

  String _extraerNombrePerfil(dynamic profile, dynamic fallback) {
    if (profile is Map) {
      final name = (profile['name'] ?? '').toString();
      final lastname = (profile['lastname'] ?? '').toString();
      final full = '$name $lastname'.trim();
      if (full.isNotEmpty) return full;
    }
    return (fallback ?? 'Usuario').toString();
  }

  String _extraerCorreoPerfil(dynamic profile, dynamic fallback) {
    if (profile is Map && profile['email'] != null) {
      return profile['email'].toString();
    }
    return (fallback ?? '').toString();
  }

  Map<String, dynamic> _estiloClaseIa(String claseRaw) {
    final c = claseRaw.replaceAll(' ', '').toLowerCase();
    if (c.contains('muyrapido') || c.contains('muyrápido')) {
      return {
        'label': 'Muy rápido',
        'bg': const Color(0xFFDCFCE7),
        'fg': const Color(0xFF15803D),
      };
    } else if (c.contains('rapido') || c.contains('rápido')) {
      return {
        'label': 'Rápido',
        'bg': const Color(0xFFDBEAFE),
        'fg': const Color(0xFF1D4ED8),
      };
    } else if (c.contains('muylento')) {
      return {
        'label': 'Muy lento',
        'bg': const Color(0xFFFEE2E2),
        'fg': const Color(0xFFB91C1C),
      };
    } else if (c.contains('lento')) {
      return {
        'label': 'Lento',
        'bg': const Color(0xFFFEF9C3),
        'fg': const Color(0xFFA16207),
      };
    }
    return {
      'label': claseRaw.isEmpty ? 'Por determinar' : claseRaw,
      'bg': const Color(0xFFF1F5F9),
      'fg': const Color(0xFF334155),
    };
  }

  double _leerProb(Map probs, List<String> claves) {
    for (final k in claves) {
      if (probs[k] != null) {
        return double.tryParse(probs[k].toString()) ?? 0.0;
      }
    }
    return 0.0;
  }

  Widget _buildCajaPrediccionIa() {
    final source = _prediccionIa ?? _pqr;
    final rawClase = (source['prediccion'] ??
            source['prediction'] ??
            _pqr['prediction'] ??
            '')
        .toString()
        .trim();

    final rawProbs = source['probabilidades'] ??
        source['probabilities'] ??
        _pqr['probabilidades'] ??
        _pqr['probabilities'];

    if (rawClase.isEmpty && rawProbs == null) {
      return const SizedBox.shrink();
    }

    double pMuyRapido = 0.0;
    double pRapido = 0.0;
    double pLento = 0.0;
    double pMuyLento = 0.0;
    bool tieneProbs = false;

    if (rawProbs is Map && rawProbs.isNotEmpty) {
      tieneProbs = true;
      pMuyRapido = _leerProb(rawProbs, ['MuyRapido', 'Muy rápido', 'Muy rapido', 'muy_rapido']);
      pRapido = _leerProb(rawProbs, ['Rapido', 'Rápido', 'rapido']);
      pLento = _leerProb(rawProbs, ['Lento', 'lento']);
      pMuyLento = _leerProb(rawProbs, ['MuyLento', 'Muy lento', 'muy_lento']);

      final suma = pMuyRapido + pRapido + pLento + pMuyLento;
      if (suma > 0 && suma <= 1.5) {
        pMuyRapido *= 100.0;
        pRapido *= 100.0;
        pLento *= 100.0;
        pMuyLento *= 100.0;
      }
    }

    final rawConf = source['confianza'] ??
        source['confidence'] ??
        _pqr['predictionConfidence'] ??
        _pqr['confidence'];
    double? confianza;
    if (rawConf != null) {
      final val = double.tryParse(rawConf.toString());
      if (val != null) {
        confianza = (val > 0 && val <= 1.0) ? val * 100.0 : val;
      }
    } else if (tieneProbs) {
      confianza = [pMuyRapido, pRapido, pLento, pMuyLento]
          .reduce((a, b) => a > b ? a : b);
    }

    final estilo = _estiloClaseIa(rawClase);
    final textoPill = confianza != null
        ? '${estilo['label']} (${confianza.toStringAsFixed(2)}% confianza)'
        : '${estilo['label']}';

    Widget itemProb(String titulo, double valor) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${valor.toStringAsFixed(2)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiempo estimado de respuesta (IA):',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: estilo['bg'] as Color,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              textoPill,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: estilo['fg'] as Color,
              ),
            ),
          ),
          if (tieneProbs) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: itemProb('Muy rápido', pMuyRapido)),
                const SizedBox(width: 10),
                Expanded(child: itemProb('Rápido', pRapido)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: itemProb('Lento', pLento)),
                const SizedBox(width: 10),
                Expanded(child: itemProb('Muy lento', pMuyLento)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radicado = (_pqr['reference'] ?? _pqr['id'] ?? 'SIN-RADICADO').toString();
    final nombreUsuario = _extraerNombrePerfil(_pqr['userProfile'], _pqr['user']);
    final correoUsuario = _extraerCorreoPerfil(_pqr['userProfile'], _pqr['user']);
    final estado = _obtenerTextoEstado(_pqr['status']);
    final tipo = _obtenerTextoTipo(_pqr['type']);
    final categoria = _obtenerTextoCategoria(_pqr['category']);
    final asunto = (_pqr['subject'] ?? '').toString();
    final descripcion = (_pqr['description'] ?? '').toString();
    final fechaCreacion = _formatearFechaCorta(_pqr['recievedDate']);
    final ultimaActualizacion = _formatearFechaCorta(_pqr['updatedDate']);

    final respuesta = (_pqr['response'] ?? '').toString();
    final tieneRespuesta = respuesta.isNotEmpty ||
        _pqr['employeeProfile'] != null ||
        _pqr['responseDate'] != null;
    final nombreEmpleado =
        _extraerNombrePerfil(_pqr['employeeProfile'], _pqr['employee']);
    final correoEmpleado =
        _extraerCorreoPerfil(_pqr['employeeProfile'], _pqr['employee']);
    final dependencia =
        (_pqr['department'] ?? 'Dirección de operaciones').toString();
    final fechaRespuesta = _formatearFechaCorta(_pqr['responseDate']);

    final List traceability =
        (_pqr['traceability'] is List) ? List.from(_pqr['traceability']) : [];

    return QuejappNavbar(
      rutaActual: 'Mis Radicados',
      child: RefreshIndicator(
        color: naranjaPrincipal,
        onRefresh: _refrescarDetalleEnTiempoReal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles del Radicado',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: naranjaPrincipal,
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: naranjaPrincipal,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: naranjaPrincipal, width: 1.2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'Volver',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    color: naranjaPrincipal,
                    backgroundColor: const Color(0xFFFFEDD5),
                  ),
                ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCampoDato('ID del Radicado:', radicado),
                    _buildCampoDato('Nombre del Usuario:', nombreUsuario),
                    _buildCampoDato('Correo Electrónico:', correoUsuario),
                    _buildCampoDato('Estado:', estado),
                    _buildCampoDato('Tipo:', tipo),
                    _buildCampoDato('Categoría:', categoria),
                    _buildCampoDato('Asunto:', asunto),
                    _buildCampoDato('Descripción:', descripcion),
                    _buildCampoDato('Fecha de Creación:', fechaCreacion),
                    _buildCampoDato('Última Actualización:', ultimaActualizacion),

                    _buildCajaPrediccionIa(),

                    if (tieneRespuesta) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Detalles de Respuesta',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: naranjaPrincipal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCampoDato('Empleado:', nombreEmpleado),
                      _buildCampoDato('Correo Electrónico:', correoEmpleado),
                      _buildCampoDato('Dependencia:', dependencia),
                      _buildCampoDato('Fecha de Respuesta:', fechaRespuesta),
                      _buildCampoDato('Respuesta:', respuesta),
                    ],

                    const SizedBox(height: 14),

                    const Text(
                      'Historial de Cambios',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (traceability.isEmpty)
                      _buildTarjetaHistorial(
                        fecha: fechaCreacion,
                        accion: 'PQRS Radicada',
                        autor: correoUsuario.isNotEmpty
                            ? correoUsuario
                            : nombreUsuario,
                      )
                    else
                      ...traceability.map((item) {
                        final mapItem = item is Map ? item : {};
                        final fechaItem = _formatearFechaCorta(mapItem['date']);
                        final accionItem =
                            (mapItem['status'] ?? 'Actualización').toString();
                        final autorItem =
                            (mapItem['performedBy'] ?? correoUsuario).toString();

                        return _buildTarjetaHistorial(
                          fecha: fechaItem,
                          accion: accionItem,
                          autor: autorItem,
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15.5,
            height: 1.4,
            color: Color(0xFF0F172A),
          ),
          children: [
            TextSpan(
              text: '$etiqueta ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            TextSpan(
              text: valor,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaHistorial({
    required String fecha,
    required String accion,
    required String autor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4.5,
                color: naranjaPrincipal,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$fecha: ',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: naranjaPrincipal,
                              ),
                            ),
                            TextSpan(
                              text: accion,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'realizado por ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF475569),
                              ),
                            ),
                            TextSpan(
                              text: autor,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}