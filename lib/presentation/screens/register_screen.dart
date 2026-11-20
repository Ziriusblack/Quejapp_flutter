import 'package:flutter/material.dart';
import '../../data/network/api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fechaController = TextEditingController();

  DateTime? _fechaNacimientoSeleccionada;
  String _generoSeleccionado = 'Masculino';
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fechaInicial = DateTime(hoy.year - 18, hoy.month, hoy.day);

    DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaNacimientoSeleccionada ?? fechaInicial,
      firstDate: DateTime(1930),
      lastDate: hoy,
    );

    if (fechaElegida != null) {
      String dia = fechaElegida.day.toString().padLeft(2, '0');
      String mes = fechaElegida.month.toString().padLeft(2, '0');
      String anio = fechaElegida.year.toString();
      setState(() {
        _fechaNacimientoSeleccionada = fechaElegida;
        _fechaController.text = '$dia/$mes/$anio';
      });
    }
  }

  bool _esMayorDeEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad >= 18;
  }

  int _mapearGeneroAEntero(String genero) {
    switch (genero) {
      case 'Masculino':
        return 0;
      case 'Femenino':
        return 1;
      default:
        return 2;
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final fecha = _fechaNacimientoSeleccionada!;
    final String birthdateIso =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    bool exito = await ApiService.register(
      firstname: _nombreController.text.trim(),
      lastname: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      birthdateIso: birthdateIso,
      gender: _mapearGeneroAEntero(_generoSeleccionado),
    );

    setState(() => _isLoading = false);

    if (exito) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada con éxito. Ahora puedes iniciar sesión.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. Verifica tu conexión o si el correo ya existe.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 14.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF0592A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO CLICABLE HACIA HOME
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.12,
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa el formulario para registrarte',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Nombre'),
                  TextFormField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration('Juan'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (value.trim().length < 2) {
                        return 'Ingresa un nombre válido';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Apellido'),
                  TextFormField(
                    controller: _apellidoController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration('Pérez'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El apellido es obligatorio';
                      }
                      if (value.trim().length < 2) {
                        return 'Ingresa un apellido válido';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Correo electrónico'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration('tu@email.com'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El correo electrónico es obligatorio';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Contraseña'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _buildInputDecoration('••••••••'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Confirmar contraseña'),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _buildInputDecoration('••••••••'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Fecha de nacimiento'),
                  TextFormField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: _seleccionarFecha,
                    decoration: _buildInputDecoration(
                      'dd/mm/aaaa',
                      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
                    ),
                    validator: (value) {
                      if (_fechaNacimientoSeleccionada == null || value == null || value.isEmpty) {
                        return 'Selecciona tu fecha de nacimiento';
                      }
                      if (!_esMayorDeEdad(_fechaNacimientoSeleccionada!)) {
                        return 'Debes ser mayor de 18 años para registrarte';
                      }
                      return null;
                    },
                  ),

                  _buildLabel('Género'),
                  DropdownButtonFormField<String>(
                    value: _generoSeleccionado,
                    decoration: _buildInputDecoration(''),
                    items: ['Masculino', 'Femenino', 'Otro'].map((String valor) {
                      return DropdownMenuItem(value: valor, child: Text(valor, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (val) => setState(() => _generoSeleccionado = val!),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0592A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _registrar,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Crear cuenta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF0592A),
                      side: const BorderSide(color: Color(0xFFF0592A), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('← Volver al inicio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}