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

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await ApiService.registrarNuevaSolicitud(
      type: _tipoSeleccionado,
      category: _categoriaSeleccionada,
      subject: _asuntoController.text.trim(),
      description: _descripcionController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado == 'OK') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud registrada con éxito'),
          backgroundColor: Color(0xFF16A34A),
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
                    const SizedBox(height: 24),

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