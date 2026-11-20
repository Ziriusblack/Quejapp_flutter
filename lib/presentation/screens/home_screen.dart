import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/quejapp_navbar.dart';
import '../../data/network/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color naranjaPrincipal = const Color(0xFFF37003);
  final Color naranjaBoton = const Color(0xFFE04800);
  final Color azulOscuro = const Color(0xFF0F172A);

  String _recibidas = '0';
  String _resueltas = '0';
  String _diasPromedio = '0 días';
  String _satisfaccion = '0%';

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

Future<void> _cargarEstadisticas() async {
    final stats = await ApiService.obtenerEstadisticasHome();
    if (stats != null && mounted) {
      setState(() {
        _recibidas = (stats['totalPqrs'] ?? 0).toString();
        _resueltas = (stats['closedPqrs'] ?? 0).toString();
        
        final double promedio = (stats['averageDaysToResolve'] ?? 0).toDouble();
        _diasPromedio = '${promedio.toStringAsFixed(1)} días';
        
        final double satisfaccion = (stats['satisfactionRate'] ?? 0).toDouble();
        _satisfaccion = '${satisfaccion.round()}%';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return QuejappNavbar(
      rutaActual: 'Inicio',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. HERO SECTION + BENEFICIOS + GRID
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Logo circular grande recortado limpio
                  Center(
                    child: ClipOval(
                      child: Transform.scale(
                        scale: 1.12, // Elimina el margen blanco cuadrado
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 240,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Título bicolor alineado a la izquierda
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        height: 1.25,
                      ),
                      children: [
                        const TextSpan(text: 'Gestión inteligente de\nPQRS para '),
                        TextSpan(text: 'Transcaribe', style: TextStyle(color: naranjaBoton)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Subtítulo
                  const Text(
                    'Conectando a los ciudadanos de Cartagena con un mejor servicio de transporte',
                    style: TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // 3 Tarjetas de características
                  _buildFeatureCard(
                    icono: Icons.bolt_rounded,
                    titulo: 'Gestión Rápida',
                    subtitulo: 'Procesa quejas y reclamos en tiempo real',
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureCard(
                    icono: Icons.shield_outlined,
                    titulo: 'Seguimiento Seguro',
                    subtitulo: 'Rastreo completo de cada solicitud',
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureCard(
                    icono: Icons.people_outline_rounded,
                    titulo: 'Para la Comunidad',
                    subtitulo: 'Mejorando el servicio de transporte público',
                  ),
                  const SizedBox(height: 24),

                  // Botón "Comenzar Ahora"
                  SizedBox(
                    width: 210,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: naranjaBoton,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Comenzar Ahora',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Cuadrícula 2x2 de tarjetas con imagen
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      _buildImageGridCard(
                        titulo: 'Sistema\nPQRS',
                        rutaImagen: 'assets/images/transcaribe.png',
                        colorRespaldo: const Color(0xFF8C4A32),
                      ),
                      _buildImageGridCard(
                        titulo: 'Seguimiento',
                        rutaImagen: 'assets/images/seguimiento.jpg',
                        colorRespaldo: const Color(0xFF64748B),
                      ),
                      _buildImageGridCard(
                        titulo: 'Comunidad',
                        rutaImagen: 'assets/images/comunidad.jpg',
                        colorRespaldo: const Color(0xFF786843),
                      ),
                      _buildImageGridCard(
                        titulo: 'Respuesta\nRápida',
                        rutaImagen: 'assets/images/rapido.png',
                        colorRespaldo: const Color(0xFF4C1D95),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ==========================================
                  // 2. TARJETAS VERTICALES DE ESTADÍSTICAS
                  // ==========================================
                  _buildVerticalStatCard(
                    icono: Icons.inventory_2_outlined,
                    colorIcono: const Color(0xFFF37003),
                    colorFondoIcono: const Color(0xFFFFEDD5),
                    titulo: 'PQRS Recibidas',
                    valor: _recibidas,
                    colorValor: const Color(0xFFF37003),
                  ),
                  const SizedBox(height: 16),
                  _buildVerticalStatCard(
                    icono: Icons.check_circle_outline_rounded,
                    colorIcono: const Color(0xFF16A34A),
                    colorFondoIcono: const Color(0xFFDCFCE7),
                    titulo: 'Resueltas',
                    valor: _resueltas,
                    colorValor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 16),
                  _buildVerticalStatCard(
                    icono: Icons.access_time_rounded,
                    colorIcono: const Color(0xFF2563EB),
                    colorFondoIcono: const Color(0xFFDBEAFE),
                    titulo: 'Días Promedio',
                    valor: _diasPromedio,
                    colorValor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),
                  _buildVerticalStatCard(
                    icono: Icons.star_border_rounded,
                    colorIcono: const Color(0xFFD97706),
                    colorFondoIcono: const Color(0xFFFEF3C7),
                    titulo: 'Satisfacción',
                    valor: _satisfaccion,
                    colorValor: const Color(0xFFD97706),
                  ),

                  // ==========================================
                  // 3. SECCIÓN: ¿CÓMO FUNCIONA NUESTRO SISTEMA?
                  // ==========================================
                  const Center(
                    child: Text(
                      '¿Cómo funciona\nnuestro sistema?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Un proceso simple y transparente para que tu voz sea escuchada',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _buildStepCard(
                    titulo: 'Crea tu PQRS',
                    descripcion:
                        'Completa el formulario con los detalles de tu petición, queja, reclamo o sugerencia. El proceso es rápido y sencillo.',
                  ),
                  const SizedBox(height: 16),
                  _buildStepCard(
                    titulo: 'Seguimiento',
                    descripcion:
                        'Recibe un número de radicado único para hacer seguimiento del estado de tu solicitud en tiempo real.',
                  ),
                  const SizedBox(height: 16),
                  _buildStepCard(
                    titulo: 'Resolución',
                    descripcion:
                        'Nuestro equipo trabajará en tu solicitud y te notificaremos cuando esté resuelta, junto con las acciones tomadas.',
                  ),
                  const SizedBox(height: 44),
                ],
              ),
            ),

            // ==========================================
            // 4. BANNER NARANJA CTA
            // ==========================================
            Container(
              width: double.infinity,
              color: naranjaPrincipal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
              child: Column(
                children: const [
                  Text(
                    '¿Tienes alguna\ninquietud sobre\nnuestro servicio?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No esperes más. Tu opinión nos ayuda a mejorar cada día.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),

            // ==========================================
            // 5. FOOTER OSCURO
            // ==========================================
            Container(
              width: double.infinity,
              color: azulOscuro,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: naranjaPrincipal),
                        child: const Center(
                          child: Text(
                            'Q',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'QuejAPP',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Sistema PQRS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(height: 28),

                  const Text(
                    'Contacto',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildFooterRow(Icons.location_on_outlined, 'Calle 123 #45-67, Cartagena'),
                  const SizedBox(height: 10),
                  _buildFooterRow(Icons.phone_outlined, '+57 300 123 4567'),
                  const SizedBox(height: 10),
                  _buildFooterRow(Icons.email_outlined, 'contacto@quejapp.com'),
                  const SizedBox(height: 28),

                  const Text(
                    'Horarios de atención',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildFooterRow(Icons.calendar_today_outlined, 'Lunes a Viernes: 8:00 AM - 6:00 PM'),
                  const SizedBox(height: 10),
                  _buildFooterRow(Icons.access_time_outlined, 'Sábados: 8:00 AM - 2:00 PM'),
                  const SizedBox(height: 28),

                  Divider(color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2025 Transcaribe - Todos los derechos\nreservados',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFeatureCard({required IconData icono, required String titulo, required String subtitulo}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: naranjaPrincipal, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridCard({
    required String titulo,
    required String rutaImagen,
    required Color colorRespaldo,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            rutaImagen,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: colorRespaldo),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            right: 10,
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStatCard({
    required IconData icono,
    required Color colorIcono,
    required Color colorFondoIcono,
    required String titulo,
    required String valor,
    required Color colorValor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colorFondoIcono),
            child: Icon(icono, color: colorIcono, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colorValor),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required String titulo, required String descripcion}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: naranjaPrincipal, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
      ],
    );
  }
}