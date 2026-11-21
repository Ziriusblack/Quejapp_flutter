import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/pqr_form_screen.dart';
import '../screens/mis_radicados_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_radicados_screen.dart';

class QuejappNavbar extends StatefulWidget {
  final String rutaActual;
  final Widget child;

  const QuejappNavbar({
    super.key,
    required this.rutaActual,
    required this.child,
  });

  @override
  State<QuejappNavbar> createState() => _QuejappNavbarState();
}

class _QuejappNavbarState extends State<QuejappNavbar> {
  bool _menuAbierto = false;
  String _rol = 'INVITADO';
  final Color naranjaPrincipal = const Color(0xFFF37003);

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

  Future<void> _cargarRol() async {
    final rolGuardado = await ApiService.getRolActual();
    if (mounted) {
      setState(() => _rol = rolGuardado);
    }
  }

  Future<void> _cerrarSesion() async {
    await ApiService.logout();
    setState(() {
      _rol = 'INVITADO';
      _menuAbierto = false;
    });
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _irAlHome() {
    setState(() => _menuAbierto = false);
    if (widget.rutaActual != 'Inicio') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. BARRA SUPERIOR NARANJA (NAVBAR)
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: naranjaPrincipal,
              child: Row(
                children: [
                  // LOGO + NOMBRE CLICABLES HACIA HOME
                  GestureDetector(
                    onTap: _irAlHome,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        ClipOval(
                          child: Transform.scale(
                            scale: 1.12,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'QuejAPP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _menuAbierto ? Icons.close : Icons.menu,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() => _menuAbierto = !_menuAbierto);
                    },
                  ),
                ],
              ),
            ),

            // 2. MENÚ DESPLEGABLE SEGÚN EL ROL
            if (_menuAbierto)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _construirOpcionesMenu(),
                ),
              ),

            // 3. CONTENIDO DE LA PANTALLA
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }

  List<Widget> _construirOpcionesMenu() {
    if (_rol == 'INVITADO') {
      return [
        _buildMenuItem('Inicio', _irAlHome),
        const SizedBox(height: 6),
        _buildMenuItem('Ingresar', () {
          setState(() => _menuAbierto = false);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }),
        const SizedBox(height: 6),
        _buildMenuItem('Registrarse', () {
          setState(() => _menuAbierto = false);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }),
      ];
    }

    if (_rol == 'USER') {
      return [
        _buildMenuItem('Mis Radicados', () {
          setState(() => _menuAbierto = false);
          if (widget.rutaActual != 'Mis Radicados') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MisRadicadosScreen()),
            );
          }
        }),
        const SizedBox(height: 6),
        _buildMenuItem('Nuevo', () {
          setState(() => _menuAbierto = false);
          if (widget.rutaActual != 'Nuevo') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PqrFormScreen()),
            );
          }
        }),
        const SizedBox(height: 12),
        _buildLogoutButton(),
      ];
    }

    return [
    _buildMenuItem('Dashboard', () {
   setState(() => _menuAbierto = false);
    if (widget.rutaActual != 'Dashboard') {
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
  }
}),
    _buildMenuItem('Radicados', () {
      setState(() => _menuAbierto = false);
      if (widget.rutaActual != 'Radicados') {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminRadicadosScreen()));
      }
    }),
      const SizedBox(height: 12),
      _buildLogoutButton(),
    ];
  }

  Widget _buildMenuItem(String titulo, VoidCallback onTap) {
    final bool activo = widget.rutaActual == titulo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: activo ? naranjaPrincipal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          titulo,
          style: TextStyle(
            color: activo ? Colors.white : const Color(0xFF334155),
            fontSize: 16,
            fontWeight: activo ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: naranjaPrincipal,
        side: BorderSide(color: naranjaPrincipal, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _cerrarSesion,
      child: const Text(
        'Cerrar sesión',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}