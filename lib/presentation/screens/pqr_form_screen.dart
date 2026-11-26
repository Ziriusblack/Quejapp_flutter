import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../widgets/quejapp_navbar.dart';
import 'mis_radicados_screen.dart';

class PqrFormScreen extends StatefulWidget {
  const PqrFormScreen({super.key});

  @override
  State<PqrFormScreen> createState() => _PqrFormScreenState();
}

class _PqrFormScreenState extends State<PqrFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _descripcionController = TextEditingController();

  int _tipoSeleccionado = 0; // 0: Petición, 1: Queja, 2: Reclamo, 3: Sugerencia, 4: Felicitación
  int _categoriaSeleccionada = 0;
  bool _isLoading = false;
  bool _cargandoIa = false;
  Map<String, dynamic>? _prediccionIa;

  final Color naranjaPrincipal = const Color(0xFFF37003);

  final List _tiposSolicitud = [
    {
      'valor': 0,
      'emoji': '📋',
      'titulo': 'Petición',
      'subtitulo': 'Solicitud de información o servicio',
      'colorFondo': const Color(0xFFEFF6FF),
      'colorBorde': const Color(0xFF93C5FD),
      'colorTexto': const Color(0xFF1E3A8A),
      'colorSubtexto': const Color(0xFF2563EB),
    },
    {
      'valor': 1,
      'emoji': '😔',
      'titulo': 'Queja',
      'subtitulo': 'Expresión de insatisfacción',
      'colorFondo': const Color(0xFFFEF2F2),
      'colorBorde': const Color(0xFFFCA5A5),
      'colorTexto': const Color(0xFF7F1D1D),
      'colorSubtexto': const Color(0xFFDC2626),
    },
    {
      'valor': 2,
      'emoji': '⚠️',
      'titulo': 'Reclamo',
      'subtitulo': 'Exigencia de corrección o compensación',
      'colorFondo': const Color(0xFFFFFBEB),
      'colorBorde': const Color(0xFFFCD34D),
      'colorTexto': const Color(0xFF78350F),
      'colorSubtexto': const Color(0xFFD97706),
    },
    {
      'valor': 3,
      'emoji': '💡',
      'titulo': 'Sugerencia',
      'subtitulo': 'Propuesta de mejora',
      'colorFondo': const Color(0xFFF0FDF4),
      'colorBorde': const Color(0xFF86EFAC),
      'colorTexto': const Color(0xFF14532D),
      'colorSubtexto': const Color(0xFF16A34A),
    },
    {
      'valor': 4,
      'emoji': '🎉',
      'titulo': 'Felicitación',
      'subtitulo': 'Reconocimiento positivo',
      'colorFondo': const Color(0xFFFAF5FF),
      'colorBorde': const Color(0xFFD8B4FE),
      'colorTexto': const Color(0xFF581C87),
      'colorSubtexto': const Color(0xFF9333EA),
    },
  ];

  final List _categorias = [
    {'valor': 0, 'nombre': 'Servicio de Buses'},
    {'valor': 1, 'nombre': 'Estaciones y Portales'},
    {'valor': 2, 'nombre': 'Tarjetas y Recargas'},
    {'valor': 3, 'nombre': 'Atención al Usuario'},
    {'valor': 4, 'nombre': 'Seguridad'},
    {'valor': 5, 'nombre': 'Otro'},
  ];

  @override
  void dispose() {
    _asuntoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Color _colorPorPrediccion(String etiqueta) {
    switch (etiqueta) {
      case 'MuyRapido':
        return const Color(0xFF16A34A);
      case 'Rapido':
        return const Color(0xFF2563EB);
      case 'Lento':
        return const Color(0xFFD97706);
      case 'MuyLento':
      default:
        return const Color(0xFFDC2626);
    }
  }

  Future<void> _estimarTiempoConIa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _cargandoIa = true);

    final respuesta = await ApiService.predecirTiempoPqr(
      type: _tipoSeleccionado,
      category: _categoriaSeleccionada,
      subject: _asuntoController.text.trim(),
      description: _descripcionController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _cargandoIa = false;
      _prediccionIa = respuesta;
    });

    if (respuesta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con la Red Neuronal. Intenta nuevamente en unos segundos.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final pred = _prediccionIa ??
        await ApiService.predecirTiempoPqr(
          type: _tipoSeleccionado,
          category: _categoriaSeleccionada,
          subject: _asuntoController.text.trim(),
          description: _descripcionController.text.trim(),
        );

    final resultado = await ApiService.registrarNuevaSolicitud(
      type: _tipoSeleccionado,
      category: _categoriaSeleccionada,
      subject: _asuntoController.text.trim(),
      description: _descripcionController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _prediccionIa = pred;
    });

    if (!mounted) return;

    if (resultado == 'OK') {
      final textoIa = pred != null
          ? ' • Tiempo estimado IA: ${pred['prediccion_legible']} (${pred['confianza']}%)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud registrada con éxito$textoIa'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MisRadicadosScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuejappNavbar(
      rutaActual: 'Nuevo',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          children: [
            Center(
              child: Text(
                'Nueva Solicitud',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: naranjaPrincipal,
                ),
              ),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(20.0),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tipo de solicitud:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ..._tiposSolicitud.map((tipo) {
                      final bool seleccionado = _tipoSeleccionado == tipo['valor'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _tipoSeleccionado = tipo['valor'] as int);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tipo['colorFondo'] as Color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: seleccionado
                                  ? (tipo['colorSubtexto'] as Color)
                                  : (tipo['colorBorde'] as Color),
                              width: seleccionado ? 2.4 : 1.2,
                            ),
                            boxShadow: seleccionado
                                ? [
                                    BoxShadow(
                                      color: (tipo['colorBorde'] as Color).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tipo['emoji'] as String,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const Spacer(),
                                  if (seleccionado)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: tipo['colorSubtexto'] as Color,
                                      size: 22,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tipo['titulo'] as String,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: tipo['colorTexto'] as Color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tipo['subtitulo'] as String,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: tipo['colorSubtexto'] as Color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    const Text(
                      'Categoría:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _categoriaSeleccionada,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: naranjaPrincipal, width: 1.5),
                        ),
                      ),
                      items: _categorias.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['valor'] as int,
                          child: Text(
                            cat['nombre'] as String,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _categoriaSeleccionada = val);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Asunto:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _asuntoController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: naranjaPrincipal, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El asunto es obligatorio';
                        }
                        if (value.trim().length < 4) {
                          return 'Escribe un asunto más descriptivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Descripción:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: naranjaPrincipal, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es obligatoria';
                        }
                        if (value.trim().length < 10) {
                          return 'Detalla un poco más tu solicitud (mínimo 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF93C5FD), width: 1.4),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _cargandoIa ? null : _estimarTiempoConIa,
                      icon: _cargandoIa
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.psychology_rounded, size: 22),
                      label: Text(
                        _cargandoIa
                            ? 'Analizando con Red Neuronal...'
                            : 'Estimar tiempo con Red Neuronal (IA)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),

                    if (_prediccionIa != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _colorPorPrediccion(_prediccionIa!['prediccion'].toString()),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: _colorPorPrediccion(_prediccionIa!['prediccion'].toString()),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Predicción de Atención (MLP Neural Net)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tiempo estimado: ${_prediccionIa!['prediccion_legible']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _colorPorPrediccion(_prediccionIa!['prediccion'].toString()),
                                    ),
                                  ),
                                  Text(
                                    'Confianza del modelo: ${_prediccionIa!['confianza']}%',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: naranjaPrincipal,
                              side: BorderSide(color: naranjaPrincipal, width: 1.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const MisRadicadosScreen()),
                              );
                            },
                            child: const Text(
                              'Volver',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: naranjaPrincipal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isLoading ? null : _enviarSolicitud,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Enviar',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}