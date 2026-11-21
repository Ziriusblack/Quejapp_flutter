import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/network/api_service.dart';

/// Recuperar contraseña en 2 pasos: 1) correo  2) código + contraseña nueva.
/// Al terminar con éxito hace pop(true) para que el login muestre un aviso.
class ForgotPasswordScreen extends StatefulWidget {
  final String emailInicial;
  const ForgotPasswordScreen({super.key, this.emailInicial = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _naranja = Color(0xFFF37003);
  static const _texto = Color(0xFF0F172A);
  static const _gris = Color(0xFF64748B);

  late final TextEditingController _email = TextEditingController(text: widget.emailInicial);
  final _codigo = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  int _paso = 0; // 0 = pedir correo, 1 = poner código
  bool _cargando = false;
  bool _verPass = false;
  String? _error;
  int _espera = 0; // segundos para poder reenviar
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _codigo.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    _timer?.cancel();
    setState(() => _espera = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  Future<void> _enviarCodigo() async {
    final correo = _email.text.trim();
    if (!correo.contains('@') || !correo.contains('.')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    final err = await ApiService.solicitarCodigoRecuperacion(correo);
    if (!mounted) return;
    setState(() => _cargando = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _paso = 1);
    _iniciarEspera();
  }

  Future<void> _cambiar() async {
    if (_codigo.text.trim().length != 6) {
      setState(() => _error = 'El código tiene 6 dígitos.');
      return;
    }
    if (_pass.text.length < 8) {
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    final err = await ApiService.restablecerContrasena(
      email: _email.text.trim(),
      code: _codigo.text.trim(),
      newPassword: _pass.text,
    );
    if (!mounted) return;
    setState(() => _cargando = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, true);
  }

  InputDecoration _deco(String label, {IconData? icono, Widget? sufijo}) => InputDecoration(
        labelText: label,
        prefixIcon: icono == null ? null : Icon(icono, color: _gris),
        suffixIcon: sufijo,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _naranja, width: 1.8)),
      );

  Widget _boton(String t, VoidCallback? onTap) => SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _naranja,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _cargando ? null : onTap,
          child: _cargando
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      );

  Widget _paso0() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _texto)),
        const SizedBox(height: 10),
        const Text('Escribe el correo de tu cuenta y te enviaremos un código de 6 dígitos para crear una contraseña nueva.',
            style: TextStyle(color: _gris, height: 1.4)),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: _deco('Correo electrónico', icono: Icons.mail_outline),
          onSubmitted: (_) => _enviarCodigo(),
        ),
        const SizedBox(height: 20),
        _boton('Enviar código', _enviarCodigo),
      ]);

  Widget _paso1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Revisa tu correo',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _texto)),
        const SizedBox(height: 10),
        Text('Si ${_email.text.trim()} está registrado, recibirás un código de 6 dígitos en unos minutos (revisa también spam). Vence en 15 minutos.',
            style: const TextStyle(color: _gris, height: 1.4)),
        const SizedBox(height: 24),
        TextField(
          controller: _codigo,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 10),
          decoration: _deco('Código de 6 dígitos').copyWith(counterText: ''),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pass,
          obscureText: !_verPass,
          decoration: _deco('Contraseña nueva', icono: Icons.lock_outline,
              sufijo: IconButton(
                icon: Icon(_verPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _gris),
                onPressed: () => setState(() => _verPass = !_verPass),
              )),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pass2,
          obscureText: !_verPass,
          decoration: _deco('Repite la contraseña', icono: Icons.lock_outline),
          onSubmitted: (_) => _cambiar(),
        ),
        const SizedBox(height: 20),
        _boton('Cambiar contraseña', _cambiar),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_espera > 0 || _cargando) ? null : _enviarCodigo,
          child: Text(_espera > 0 ? 'Reenviar código en ${_espera}s' : 'Reenviar código',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => setState(() {
            _paso = 0;
            _error = null;
          }),
          child: const Text('Usar otro correo', style: TextStyle(color: _gris)),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _naranja,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Recuperar contraseña', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.lock_reset_rounded, size: 56, color: _naranja),
              const SizedBox(height: 14),
              if (_paso == 0) _paso0() else _paso1(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
