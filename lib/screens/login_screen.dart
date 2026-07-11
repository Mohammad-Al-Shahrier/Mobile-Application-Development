import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _passwordHidden = true;
  bool _isLoading      = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Login via AuthController ──────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await AuthController.login(
      email:    _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    // ── Check role and route accordingly ──
    final uid  = AuthController.currentUid!;
    final role = await AuthController.getUserRole(uid);

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else if (role == 'service_provider') {
      Navigator.pushReplacementNamed(context, '/provider_dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  // ── Forgot password ───────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first, then tap Forgot Password.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final error = await AuthController.sendPasswordReset(email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Reset email sent! Check your inbox.'),
      backgroundColor: error != null ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ══════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const SizedBox(height: 80),
                Image.asset('assets/images/logo.png', width: 140, height: 140),
                const SizedBox(height: 15),
                const Text('Login to Your Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 40),

                // Email
                _field(
                  ctrl:     _emailCtrl,
                  hint:     'Enter your email',
                  icon:     Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 20),

                // Password
                _field(
                  ctrl:    _passwordCtrl,
                  hint:    'Enter your password',
                  icon:    Icons.lock_outline,
                  obscure: _passwordHidden,
                  suffix:  IconButton(
                    onPressed: () =>
                        setState(() => _passwordHidden = !_passwordHidden),
                    icon: Icon(
                      _passwordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey, size: 22,
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?',
                        style: TextStyle(
                            color: Color(0xFFD9D9D9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 30),

                // Login button
                SizedBox(
                  width: 190,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109DFF),
                      disabledBackgroundColor:
                          const Color(0xFF109DFF).withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 15),

                // Sign up link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't Have an Account? ",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/registration'),
                    child: const Text('Sign up',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white)),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure      = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        controller:   ctrl,
        obscureText:  obscure,
        keyboardType: keyboard,
        validator:    validator,
        decoration: InputDecoration(
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon:     Icon(icon, color: Colors.black),
          suffixIcon:     suffix,
          hintText:       hint,
          hintStyle:      const TextStyle(color: Colors.grey, fontSize: 15),
        ),
      ),
    );
  }
}