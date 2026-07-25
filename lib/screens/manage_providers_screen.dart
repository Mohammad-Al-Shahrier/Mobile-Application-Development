import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/queue_controller.dart';

/// ============================================================
/// MANAGE PROVIDERS — QEasy (Admin)
///
/// Lists every service center and lets the admin:
///   - Create a new service_provider account and assign it to a center
///   - Unassign the current provider
///   - Pause/resume a center's live queue
/// ============================================================
class ManageProvidersScreen extends StatefulWidget {
  const ManageProvidersScreen({super.key});

  @override
  State<ManageProvidersScreen> createState() => _ManageProvidersScreenState();
}

class _ManageProvidersScreenState extends State<ManageProvidersScreen> {
  final _db = FirebaseFirestore.instance;

  static const _bg0 = Color(0xFF0D1117);
  static const _bg1 = Color(0xFF161B22);
  static const _bdr = Color(0xFF30363D);
  static const _acc = Color(0xFF3B82F6);
  static const _grn = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _togglePause(String centerId, bool paused) async {
    final error = await QueueController.setQueuePaused(centerId, paused);
    if (error != null) _snack(error, ok: false);
  }

  Future<void> _unassign(String centerId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unassign Provider', style: TextStyle(color: Colors.white)),
        content: Text('Remove $name from this center? Their login stays active.',
            style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await AuthController.unassignServiceProvider(centerId);
    _snack(err ?? 'Provider unassigned', ok: err == null);
  }

  void _assignDialog(String centerId, String centerName) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _bg1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('Assign Provider — $centerName',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _input(nameCtrl, 'Full name', (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 10),
                    _input(emailCtrl, 'Email', (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    }, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _input(phoneCtrl, 'Phone', (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                        keyboard: TextInputType.phone),
                    const SizedBox(height: 10),
                    _input(passCtrl, 'Temporary password', (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    }, obscure: true),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _acc),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        final err = await AuthController.registerServiceProvider(
                          fullName: nameCtrl.text,
                          email: emailCtrl.text,
                          password: passCtrl.text,
                          phone: phoneCtrl.text,
                          serviceCenterId: centerId,
                          serviceCenterName: centerName,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _snack(err ?? 'Provider account created', ok: err == null);
                      },
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create & Assign'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _input(TextEditingController ctrl, String label,
      String? Function(String?) validator,
      {TextInputType keyboard = TextInputType.text, bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _bdr),
            borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _acc),
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      appBar: AppBar(
        backgroundColor: _bg1,
        elevation: 0,
        title: const Text('Manage Providers', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('service_centers').orderBy('name').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _acc));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No service centers yet.',
                    style: TextStyle(color: Colors.white38)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final centerId = docs[i].id;
              final name = (d['name'] ?? 'Center').toString();
              final category = (d['category'] ?? '').toString();
              final providerUid = d['assignedProviderUid'] as String?;
              final providerName = d['assignedProviderName'] as String?;
              final isPaused = (d['isPaused'] as bool?) ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bdr, width: 0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(category,
                                style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: !isPaused,
                        activeColor: _grn,
                        onChanged: (v) => _togglePause(centerId, !v),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _bg0,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(
                          providerUid != null ? Icons.person : Icons.person_off_outlined,
                          color: providerUid != null ? _grn : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            providerUid != null ? providerName ?? 'Assigned' : 'No provider assigned',
                            style: TextStyle(
                                color: providerUid != null ? Colors.white : Colors.white38,
                                fontSize: 12.5),
                          ),
                        ),
                        if (providerUid != null)
                          TextButton(
                            onPressed: () => _unassign(centerId, providerName ?? 'Provider'),
                            child: const Text('Unassign', style: TextStyle(color: _red, fontSize: 12)),
                          )
                        else
                          TextButton(
                            onPressed: () => _assignDialog(centerId, name),
                            child: const Text('Assign', style: TextStyle(color: _acc, fontSize: 12)),
                          ),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
