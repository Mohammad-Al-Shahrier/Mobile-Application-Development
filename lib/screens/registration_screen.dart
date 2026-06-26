import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl        = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _addressCtrl         = TextEditingController();
  final _dobCtrl             = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _passwordHidden        = true;
  bool _confirmPasswordHidden = true;
  bool _isLoading             = false;

  String _selectedGender = 'Male';
  static const _genders  = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      _dobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  // ── Register via AuthController ───────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await AuthController.register(
      fullName: _fullNameCtrl.text,
      email:    _emailCtrl.text,
      password: _passwordCtrl.text,
      phone:    _phoneCtrl.text,
      address:  _addressCtrl.text,
      dob:      _dobCtrl.text,
      gender:   _selectedGender,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account created! Please login.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ══════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const SizedBox(height: 40),
                Image.asset('assets/images/logo.png', width: 120, height: 120),
                const SizedBox(height: 10),
                const Text('Create Your Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Join QEasy — Skip the wait',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 28),

                _dividerLabel('Personal Information'),
                const SizedBox(height: 12),

                _field(ctrl: _fullNameCtrl, hint: 'Full name',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your full name' : null),
                const SizedBox(height: 12),

                _field(ctrl: _phoneCtrl, hint: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter phone number';
                      if (v.trim().length < 10) return 'Enter a valid phone number';
                      return null;
                    }),
                const SizedBox(height: 12),

                _field(ctrl: _addressCtrl, hint: 'Address',
                    icon: Icons.location_on_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your address' : null),
                const SizedBox(height: 12),

                _field(ctrl: _dobCtrl, hint: 'Date of birth',
                    icon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickDate,
                    suffix: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Select date of birth' : null),
                const SizedBox(height: 12),

                _dropdown(value: _selectedGender, items: _genders,
                    icon: Icons.wc_outlined, hint: 'Gender',
                    onChanged: (v) => setState(() => _selectedGender = v!)),
                const SizedBox(height: 24),

                _dividerLabel('Account Information'),
                const SizedBox(height: 12),

                _field(ctrl: _emailCtrl, hint: 'Email address',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    }),
                const SizedBox(height: 12),

                _field(ctrl: _passwordCtrl, hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _passwordHidden,
                    suffix: _eyeBtn(_passwordHidden,
                        () => setState(() => _passwordHidden = !_passwordHidden)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    }),
                const SizedBox(height: 12),

                _field(ctrl: _confirmPasswordCtrl, hint: 'Confirm password',
                    icon: Icons.lock_outline,
                    obscure: _confirmPasswordHidden,
                    suffix: _eyeBtn(_confirmPasswordHidden,
                        () => setState(() =>
                            _confirmPasswordHidden = !_confirmPasswordHidden)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    }),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109DFF),
                      disabledBackgroundColor:
                          const Color(0xFF109DFF).withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Create Account',
                            style: TextStyle(color: Colors.white,
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Login',
                        style: TextStyle(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  HELPER WIDGETS
  // ══════════════════════════════════════════════
  Widget _dividerLabel(String label) {
    return Row(children: [
      const Expanded(child: Divider(color: Colors.white30, thickness: 0.5)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
      const Expanded(child: Divider(color: Colors.white30, thickness: 0.5)),
    ]);
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure      = false,
    bool readOnly     = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller:   ctrl,
        obscureText:  obscure,
        keyboardType: keyboard,
        readOnly:     readOnly,
        onTap:        onTap,
        validator:    validator,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          prefixIcon:     Icon(icon, color: Colors.black54, size: 20),
          suffixIcon:     suffix,
          hintText:       hint,
          hintStyle:      const TextStyle(color: Colors.grey, fontSize: 14),
          errorStyle:     const TextStyle(color: Colors.yellowAccent, fontSize: 11),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: Colors.black54, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value, isExpanded: true,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              items: items.map((e) =>
                  DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _eyeBtn(bool hidden, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey, size: 20,
      ),
    );
  }
}