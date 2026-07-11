import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';

/// ============================================================
/// REGISTRATION SCREEN — QEasy
///
/// Two account types, one form:
///   • Customer         → books tickets at existing service centers.
///   • Service Center    → registers a brand-new business AND its
///                        owner's account in one step. The owner
///                        lands as a `service_provider` already
///                        linked to their own center — no admin
///                        approval step needed to get started.
/// ============================================================
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

enum _AccountType { customer, serviceCenter }

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Personal info (both account types) ─────────
  final _fullNameCtrl        = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _addressCtrl         = TextEditingController();
  final _dobCtrl             = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ── Business info (service center only) ────────
  final _centerNameCtrl  = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _avgMinutesCtrl  = TextEditingController(text: '5');

  bool _passwordHidden        = true;
  bool _confirmPasswordHidden = true;
  bool _isLoading             = false;

  String _selectedGender = 'Male';
  static const _genders  = ['Male', 'Female', 'Other'];

  String _selectedCategory = 'Hospital';
  static const _categories = ServiceCenterCategories.all;

  _AccountType _accountType = _AccountType.customer;
  bool get _isServiceCenter => _accountType == _AccountType.serviceCenter;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _centerNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _avgMinutesCtrl.dispose();
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

    final String? error;

    if (_isServiceCenter) {
      final avgMinutes = int.tryParse(_avgMinutesCtrl.text.trim()) ?? 5;
      error = await AuthController.registerServiceCenter(
        fullName:          _fullNameCtrl.text,
        email:             _emailCtrl.text,
        password:          _passwordCtrl.text,
        phone:             _phoneCtrl.text,
        address:           _addressCtrl.text,
        dob:               _dobCtrl.text,
        gender:            _selectedGender,
        centerName:        _centerNameCtrl.text,
        category:          _selectedCategory,
        description:       _descriptionCtrl.text,
        avgServiceMinutes: avgMinutes.clamp(1, 120),
      );
    } else {
      error = await AuthController.register(
        fullName: _fullNameCtrl.text,
        email:    _emailCtrl.text,
        password: _passwordCtrl.text,
        phone:    _phoneCtrl.text,
        address:  _addressCtrl.text,
        dob:      _dobCtrl.text,
        gender:   _selectedGender,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isServiceCenter
            ? '✅ Service center registered! Please login.'
            : '✅ Account created! Please login.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
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
                Text(
                  _isServiceCenter ? 'Register Your Service Center' : 'Create Your Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _isServiceCenter
                      ? 'List your business & manage your own live queue'
                      : 'Join QEasy — Skip the wait',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),

                _accountTypeToggle(),
                const SizedBox(height: 24),

                _dividerLabel(_isServiceCenter ? 'Owner Information' : 'Personal Information'),
                const SizedBox(height: 12),

                _field(ctrl: _fullNameCtrl,
                    hint: _isServiceCenter ? 'Owner / manager full name' : 'Full name',
                    icon: Icons.person_outline,
                    validator: Validators.fullName),
                const SizedBox(height: 12),

                _field(ctrl: _phoneCtrl, hint: 'Phone number',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    validator: Validators.phone),
                const SizedBox(height: 12),

                _field(ctrl: _addressCtrl,
                    hint: _isServiceCenter ? 'Business address' : 'Address',
                    icon: Icons.location_on_outlined,
                    validator: (v) => Validators.requiredField(v, label: 'Address')),
                const SizedBox(height: 12),

                _field(ctrl: _dobCtrl, hint: 'Date of birth',
                    icon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickDate,
                    suffix: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    validator: Validators.dateOfBirth),
                const SizedBox(height: 12),

                _dropdown(value: _selectedGender, items: _genders,
                    icon: Icons.wc_outlined, hint: 'Gender',
                    onChanged: (v) => setState(() => _selectedGender = v!)),

                // ── Business Information (service center only) ──
                if (_isServiceCenter) ...[
                  const SizedBox(height: 24),
                  _dividerLabel('Business Information'),
                  const SizedBox(height: 12),

                  _field(ctrl: _centerNameCtrl, hint: 'Service center / business name',
                      icon: Icons.storefront_outlined,
                      validator: (v) =>
                          Validators.requiredField(v, label: 'Business name')),
                  const SizedBox(height: 12),

                  _dropdown(value: _selectedCategory, items: _categories,
                      icon: Icons.category_outlined, hint: 'Category',
                      onChanged: (v) => setState(() => _selectedCategory = v!)),
                  const SizedBox(height: 12),

                  _field(ctrl: _descriptionCtrl, hint: 'Short description',
                      icon: Icons.notes_outlined,
                      validator: (v) =>
                          Validators.requiredField(v, label: 'Description')),
                  const SizedBox(height: 12),

                  _field(ctrl: _avgMinutesCtrl,
                      hint: 'Avg. minutes to serve one customer',
                      icon: Icons.timer_outlined,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a valid number';
                        return null;
                      }),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Used to estimate customer wait times in your queue.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                _dividerLabel('Account Information'),
                const SizedBox(height: 12),

                _field(ctrl: _emailCtrl, hint: 'Email address',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: Validators.email),
                const SizedBox(height: 12),

                _field(ctrl: _passwordCtrl, hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _passwordHidden,
                    suffix: _eyeBtn(_passwordHidden,
                        () => setState(() => _passwordHidden = !_passwordHidden)),
                    validator: Validators.password),
                const SizedBox(height: 12),

                _field(ctrl: _confirmPasswordCtrl, hint: 'Confirm password',
                    icon: Icons.lock_outline,
                    obscure: _confirmPasswordHidden,
                    suffix: _eyeBtn(_confirmPasswordHidden,
                        () => setState(() =>
                            _confirmPasswordHidden = !_confirmPasswordHidden)),
                    validator: (v) =>
                        Validators.confirmPassword(v, _passwordCtrl.text)),
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
                        : Text(
                            _isServiceCenter ? 'Register Service Center' : 'Create Account',
                            style: const TextStyle(color: Colors.white,
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

  /// Segmented toggle: Customer vs Service Center. Switching just
  /// shows/hides the business fields — nothing already typed is lost.
  Widget _accountTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: _toggleChip(
          label: 'Customer',
          icon: Icons.person_outline,
          selected: !_isServiceCenter,
          onTap: () => setState(() => _accountType = _AccountType.customer),
        )),
        Expanded(child: _toggleChip(
          label: 'Service Center',
          icon: Icons.storefront_outlined,
          selected: _isServiceCenter,
          onTap: () => setState(() => _accountType = _AccountType.serviceCenter),
        )),
      ]),
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: selected ? const Color(0xFF0047B3) : Colors.white70),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: selected ? const Color(0xFF0047B3) : Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }

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
