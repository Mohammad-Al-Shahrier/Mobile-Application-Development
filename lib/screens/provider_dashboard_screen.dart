import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/queue_controller.dart';
import '../models/queue_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';

/// ============================================================
/// PROVIDER DASHBOARD — QEasy
///
/// Full real-life queue control panel for a `service_provider`
/// account:
///   - Pause/resume accepting new bookings
///   - Call Next / Complete / Skip the live "Now Serving" ticket
///   - Add a walk-in ticket for someone without the app
///   - Cancel a waiting customer's ticket on their behalf
///   - Recall a "Skipped" (no-show) ticket back into the line
///   - See today's activity log
///   - Edit the center's own public listing details
/// ============================================================
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _busy = false;

  static const _bg0 = Color(0xFF0D1117);
  static const _bg1 = Color(0xFF161B22);
  static const _bdr = Color(0xFF30363D);
  static const _acc = Color(0xFF3B82F6);
  static const _grn = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);
  static const _amb = Color(0xFFF59E0B);

  // ── Action runner: shows errors, guards double-taps ──
  Future<void> _run(Future<String?> Function() action, {String? successMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _toast(error, isError: true);
    } else if (successMsg != null) {
      _toast(successMsg, isError: false);
    }
  }

  void _toast(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _red : _grn,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<bool> _confirm(String title, String body, {String confirmLabel = 'Confirm'}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(body, style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _acc),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _logout() async {
    await AuthController.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Add walk-in dialog ──────────────────────────
  void _addWalkInDialog(String centerId, String centerName) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _bg1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Add Walk-in Customer', style: TextStyle(color: Colors.white, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogInput(nameCtrl, 'Customer name'),
                const SizedBox(height: 10),
                _dialogInput(phoneCtrl, 'Phone (optional)', keyboard: TextInputType.phone),
              ],
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
                        if (nameCtrl.text.trim().isEmpty) return;
                        setDialogState(() => saving = true);
                        final err = await QueueController.addWalkInToken(
                          serviceCenterId: centerId,
                          serviceCenterName: centerName,
                          walkInName: nameCtrl.text,
                          phone: phoneCtrl.text,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _toast(err ?? 'Walk-in customer added to the queue', isError: err != null);
                      },
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add to Queue'),
              ),
            ],
          );
        });
      },
    );
  }

  // ── Edit center details dialog ──────────────────
  void _editCenterDialog(ServiceCenter center) {
    final nameCtrl = TextEditingController(text: center.name);
    final addressCtrl = TextEditingController(text: center.address);
    final descCtrl = TextEditingController(text: center.description);
    final minutesCtrl = TextEditingController(text: '${center.avgServiceMinutes}');
    String category = center.category.isNotEmpty ? center.category : ServiceCenterCategories.all.first;
    if (!ServiceCenterCategories.all.contains(category)) category = ServiceCenterCategories.all.first;
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _bg1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Edit Center Details', style: TextStyle(color: Colors.white, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogInput(nameCtrl, 'Business name'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: _bg1,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogDecoration('Category'),
                    items: ServiceCenterCategories.all
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 10),
                  _dialogInput(addressCtrl, 'Address'),
                  const SizedBox(height: 10),
                  _dialogInput(descCtrl, 'Description', maxLines: 3),
                  const SizedBox(height: 10),
                  _dialogInput(minutesCtrl, 'Avg. minutes per customer',
                      keyboard: TextInputType.number),
                ],
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
                        final minutes = int.tryParse(minutesCtrl.text.trim()) ?? center.avgServiceMinutes;
                        setDialogState(() => saving = true);
                        final err = await QueueController.updateCenterDetails(
                          centerId: center.id,
                          name: nameCtrl.text,
                          category: category,
                          address: addressCtrl.text,
                          description: descCtrl.text,
                          avgServiceMinutes: minutes.clamp(1, 120),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _toast(err ?? 'Center details updated', isError: err != null);
                      },
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  InputDecoration _dialogDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _bdr), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _acc), borderRadius: BorderRadius.circular(10)),
      );

  Widget _dialogInput(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogDecoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: ProfileController.currentUserStream(),
          builder: (context, userSnap) {
            final user = userSnap.data;

            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _acc));
            }
            if (user == null || user.serviceCenterId.isEmpty) {
              return _notAssignedState();
            }

            final centerId = user.serviceCenterId;

            return StreamBuilder<ServiceCenter?>(
              stream: QueueController.serviceCenterStream(centerId),
              builder: (context, centerSnap) {
                final center = centerSnap.data;

                return Column(
                  children: [
                    _header(user, center),
                    Expanded(
                      child: StreamBuilder<Map<String, dynamic>?>(
                        stream: QueueController.queueMetaStream(centerId),
                        builder: (context, metaSnap) {
                          final isPaused = (metaSnap.data?['isPaused'] as bool?) ?? false;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _pauseBar(centerId, isPaused),
                                const SizedBox(height: 16),
                                _statsRow(centerId, center?.avgServiceMinutes ?? 5),
                                const SizedBox(height: 16),
                                _nowServingCard(centerId),
                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Waiting List',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                    TextButton.icon(
                                      onPressed: _busy || center == null
                                          ? null
                                          : () => _addWalkInDialog(centerId, center.name),
                                      icon: const Icon(Icons.person_add_alt_1, size: 18, color: _acc),
                                      label: const Text('Add Walk-in', style: TextStyle(color: _acc)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _waitingList(centerId),

                                const SizedBox(height: 20),
                                _skippedSection(centerId),

                                const SizedBox(height: 20),
                                const Text('Today\'s Activity',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                _activityLog(centerId),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _notAssignedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            const Text('No Service Center Assigned',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Ask an admin to assign you to a service center before you can manage a queue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: _acc),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(UserModel user, ServiceCenter? center) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: const BoxDecoration(
        color: _bg1,
        border: Border(bottom: BorderSide(color: _bdr, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _acc, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(Helpers.initials(user.fullName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(user.serviceCenterName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (center != null)
            GestureDetector(
              onTap: () => _editCenterDialog(center),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
              ),
            ),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.logout_outlined, color: Colors.white38, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _pauseBar(String centerId, bool isPaused) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPaused ? _red.withOpacity(0.12) : _grn.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPaused ? _red : _grn, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(isPaused ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: isPaused ? _red : _grn),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPaused ? 'Queue Paused — not accepting new bookings' : 'Queue Live — accepting bookings',
              style: TextStyle(color: isPaused ? _red : _grn, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Switch(
            value: !isPaused,
            activeColor: _grn,
            onChanged: _busy ? null : (v) => _run(() => QueueController.setQueuePaused(centerId, !v)),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(String centerId, int avgServiceMinutes) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<QueueToken>>(
            stream: QueueController.waitingListStream(centerId),
            builder: (context, snap) {
              final waiting = snap.data?.length ?? 0;
              return _statCard('Waiting', '$waiting', Icons.people_alt_outlined, _amb);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<int>(
            stream: QueueController.servedTodayCountStream(centerId),
            builder: (context, snap) => _statCard('Served Today', '${snap.data ?? 0}', Icons.task_alt, _grn),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<List<QueueToken>>(
            stream: QueueController.waitingListStream(centerId),
            builder: (context, snap) {
              final waiting = snap.data?.length ?? 0;
              final mins = QueueController.estimateWaitMinutes(
                  positionAhead: waiting, avgServiceMinutes: avgServiceMinutes);
              return _statCard('Est. Wait', '${mins}m', Icons.timer_outlined, _acc);
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(color: _bg1, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _nowServingCard(String centerId) {
    return StreamBuilder<QueueToken?>(
      stream: QueueController.currentServingStream(centerId),
      builder: (context, snap) {
        final serving = snap.data;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NOW SERVING',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(serving?.tokenNumber ?? '—',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              if (serving != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Text(serving.userName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  if (serving.isWalkIn) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Walk-in', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ]),
              ],
              const SizedBox(height: 18),
              if (serving == null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _run(() => QueueController.callNextToken(centerId)),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Call Next Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0047B3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() => QueueController.completeCurrentToken(centerId)),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _grn,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final ok = await _confirm('Skip This Ticket?',
                                      'Mark ${serving.tokenNumber} (${serving.userName}) as a no-show?',
                                      confirmLabel: 'Skip');
                                  if (ok) {
                                    _run(() => QueueController.skipCurrentToken(centerId));
                                  }
                                },
                          icon: const Icon(Icons.skip_next_outlined, color: Colors.white),
                          label: const Text('Skip', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _waitingList(String centerId) {
    return StreamBuilder<List<QueueToken>>(
      stream: QueueController.waitingListStream(centerId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(color: _acc)),
          );
        }
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(color: _bg1, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('No one is waiting right now.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          );
        }
        return Column(
          children: list.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _bg1, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: _bg0, borderRadius: BorderRadius.circular(9)),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: const TextStyle(color: _acc, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(t.tokenNumber,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          if (t.isWalkIn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _amb.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Walk-in', style: TextStyle(color: _amb, fontSize: 9)),
                            ),
                          ],
                        ]),
                        Text(t.userName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final ok = await _confirm('Cancel This Ticket?',
                                'Cancel ${t.tokenNumber} for ${t.userName}?', confirmLabel: 'Cancel Ticket');
                            if (ok) {
                              _run(() => QueueController.cancelTokenAsProvider(t.id));
                            }
                          },
                    icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _skippedSection(String centerId) {
    return StreamBuilder<List<QueueToken>>(
      stream: QueueController.skippedTodayStream(centerId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No-Shows (${list.length}) — tap Recall if they return',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...list.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _red.withOpacity(0.3), width: 0.6),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.tokenNumber,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(t.userName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() => QueueController.recallSkippedToken(t.id),
                              successMsg: '${t.tokenNumber} recalled to the back of the line'),
                      icon: const Icon(Icons.replay, size: 16, color: _acc),
                      label: const Text('Recall', style: TextStyle(color: _acc, fontSize: 12)),
                    ),
                  ]),
                )),
          ],
        );
      },
    );
  }

  Widget _activityLog(String centerId) {
    return StreamBuilder<List<QueueToken>>(
      stream: QueueController.centerHistoryTodayStream(centerId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(color: _bg1, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const Text('No activity yet today.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          );
        }
        return Column(
          children: list.take(20).map((t) {
            final color = t.status == 'Served'
                ? _grn
                : t.status == 'Skipped'
                    ? _amb
                    : _red;
            final icon = t.status == 'Served'
                ? Icons.check_circle_outline
                : t.status == 'Skipped'
                    ? Icons.error_outline
                    : Icons.cancel_outlined;
            final Timestamp ts = t.servedAt ?? t.createdAt;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _bg1, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${t.tokenNumber} · ${t.userName}',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ),
                Text(Helpers.timeAgo(ts),
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            );
          }).toList(),
        );
      },
    );
  }
}
