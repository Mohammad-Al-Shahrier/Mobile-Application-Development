import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = FirebaseFirestore.instance;

  // ── Live Firestore caches ──
  List<QueryDocumentSnapshot> _users        = [];
  List<QueryDocumentSnapshot> _queues       = [];   // collection: 'queues'
  List<QueryDocumentSnapshot> _tokens       = [];   // collection: 'tokens'
  List<QueryDocumentSnapshot> _serviceCenters = []; // collection: 'service_centers'
  List<QueryDocumentSnapshot> _complaints   = [];   // collection: 'complaints'

  final List<StreamSubscription> _subs = [];

  // ── Nav ──
  int    _navIndex = 0;
  String _tokenFilter = 'All';

  // ── Clock ──
  DateTime _now = DateTime.now();
  late Timer _clockTimer;

  // ── Search ──
  final _searchCtrl = TextEditingController();
  String _searchQ   = '';

  String get _todayKey => DateTime.now().toIso8601String().substring(0, 10);

  // ── Colors ──
  static const _bg0 = Color(0xFF0D1117);
  static const _bg1 = Color(0xFF161B22);
  static const _bdr = Color(0xFF30363D);
  static const _acc = Color(0xFF3B82F6);
  static const _grn = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);
  static const _amb = Color(0xFFF59E0B);
  static const _pur = Color(0xFF8B5CF6);
  static const _cyn = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _subscribeAll();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _now = DateTime.now()); },
    );
  }

  void _subscribeAll() {
    // Users
    _subs.add(_db.collection('users').snapshots().listen((s) {
      if (mounted) setState(() => _users = s.docs);
    }));

    // Queues
    _subs.add(_db.collection('queues')
        .orderBy('createdAt', descending: true)
        .snapshots().listen((s) {
      if (mounted) setState(() => _queues = s.docs);
    }));

    // Tokens (individual queue entries)
    _subs.add(_db.collection('tokens')
        .orderBy('createdAt', descending: true)
        .snapshots().listen((s) {
      if (mounted) setState(() => _tokens = s.docs);
    }));

    // Service centers
    _subs.add(_db.collection('service_centers').snapshots().listen((s) {
      if (mounted) setState(() => _serviceCenters = s.docs);
    }));

    // Complaints
    _subs.add(_db.collection('complaints').snapshots().listen((s) {
      if (mounted) setState(() => _complaints = s.docs);
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _clockTimer.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Computed stats ──
  int get _totalUsers      => _users.length;
  int get _totalQueues     => _queues.length;
  int get _activeTokens    => _tokens.where((t) => t['status'] == 'Waiting' || t['status'] == 'Serving').length;
  int get _servedToday     => _tokens.where((t) {
    final ts = (t.data() as Map)['servedAt'];
    if (ts is! Timestamp) return false;
    final d = ts.toDate();
    return d.year == _now.year && d.month == _now.month && d.day == _now.day;
  }).length;
  int get _skippedToday    => _tokens.where((t) {
    if ((t.data() as Map)['status'] != 'Skipped') return false;
    final ts = (t.data() as Map)['createdAt'];
    if (ts is! Timestamp) return false;
    final d = ts.toDate();
    return d.year == _now.year && d.month == _now.month && d.day == _now.day;
  }).length;
  int get _pendingComplaints => _complaints.where((c) => c['status'] == 'Pending').length;
  int get _avgWaitMins {
    final waiting = _tokens.where((t) => t['status'] == 'Waiting').toList();
    if (waiting.isEmpty) return 0;
    int total = 0;
    for (final t in waiting) {
      final ts = (t.data() as Map)['createdAt'];
      if (ts is Timestamp) {
        total += _now.difference(ts.toDate()).inMinutes;
      }
    }
    return (total / waiting.length).round();
  }

  List<QueryDocumentSnapshot> get _filteredTokens {
    final base = _tokenFilter == 'All'
        ? _tokens
        : _tokens.where((t) => t['status'] == _tokenFilter).toList();
    return base;
  }

  List<QueryDocumentSnapshot> get _filteredUsers {
    if (_searchQ.isEmpty) return _users;
    final q = _searchQ;
    return _users.where((u) {
      final n = (u['fullName'] ?? '').toString().toLowerCase();
      final e = (u['email']   ?? '').toString().toLowerCase();
      return n.contains(q) || e.contains(q);
    }).toList();
  }

  // ── Hourly token data ──
  List<int> get _hourlyTokenData => List.generate(12, (i) {
    final h = 8 + i;
    return _tokens.where((t) {
      final ts = (t.data() as Map)['createdAt'];
      if (ts is! Timestamp) return false;
      final dt = ts.toDate();
      return dt.hour == h && dt.day == _now.day;
    }).length;
  });

  // ── Service center breakdown ──
  Map<String, int> get _centerBreakdown {
    final map = <String, int>{};
    for (final t in _tokens) {
      final d = t.data() as Map;
      final center = (d['serviceCenterName'] ?? d['serviceCenterId'] ?? 'Unknown').toString();
      map[center] = (map[center] ?? 0) + 1;
    }
    return map;
  }

  // ── Actions ──
  Future<void> _updateTokenStatus(String id, String status) async {
    try {
      final update = <String, dynamic>{'status': status};
      if (status == 'Serving' || status == 'Served') {
        update['servedAt'] = FieldValue.serverTimestamp();
      }
      await _db.collection('tokens').doc(id).update(update);
      _snack('Token → $status', ok: true);
    } catch (e) {
      _snack('Error: $e', ok: false);
    }
  }

  Future<void> _callNextToken(String queueId) async {
    try {
      final waiting = _tokens.where((t) =>
          t['queueId'] == queueId && t['status'] == 'Waiting').toList();
      if (waiting.isEmpty) { _snack('No waiting tokens', ok: false); return; }
      waiting.sort((a, b) {
        final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return ta.compareTo(tb);
      });
      await _db.collection('tokens').doc(waiting.first.id)
          .update({'status': 'Serving', 'servedAt': FieldValue.serverTimestamp()});
      _snack('Next token called!', ok: true);
    } catch (e) {
      _snack('Error: $e', ok: false);
    }
  }

  Future<void> _deleteUser(String uid, String name) async {
    final ok = await _confirm('Delete "$name"?', 'Removes user from Firestore.');
    if (ok) {
      await _db.collection('users').doc(uid).delete();
      _snack('User removed', ok: false);
    }
  }

  Future<void> _logout() async {
    final ok = await _confirm('Log out', 'Are you sure?');
    if (!ok) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<bool> _confirm(String title, String body) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(body, style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _overviewTab(),
          _queueTab(),
          _usersTab(),
          _reportsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ──────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final hh  = _now.hour.toString().padLeft(2, '0');
    final mm  = _now.minute.toString().padLeft(2, '0');
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final date = '${_now.day} ${months[_now.month - 1]} ${_now.year}';

    return AppBar(
      backgroundColor: _bg1,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _acc, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('Q', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('QEasy Admin', style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('$date · $hh:$mm', style: const TextStyle(
                color: Colors.white38, fontSize: 10)),
          ]),
          const Spacer(),
          // Live indicator
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: _grn, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Live', style: TextStyle(
                color: _grn, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.logout_outlined, color: Colors.white38, size: 20),
          ),
        ]),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: _bdr),
      ),
    );
  }

  // ── Bottom Nav ──────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _bg1,
        border: Border(top: BorderSide(color: _bdr, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _acc,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined), label: 'Queue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined), label: 'Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Reports'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 0 — OVERVIEW
  // ══════════════════════════════════════════════════════
  Widget _overviewTab() {
    return RefreshIndicator(
      color: _acc,
      backgroundColor: _bg1,
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── KPI 2x2 ──
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _kpi('Active Tokens',  '$_activeTokens',
                  Icons.confirmation_number_outlined, _acc, 'In queue now', true),
              _kpi('Served Today',   '$_servedToday',
                  Icons.check_circle_outline, _grn, 'Completed today', true),
              _kpi('Avg Wait',       '$_avgWaitMins min',
                  Icons.timer_outlined, _amb, 'Real-time avg', false),
              _kpi('Skipped Today',  '$_skippedToday',
                  Icons.skip_next_outlined, _red, 'No-shows today', false),
            ],
          ),

          const SizedBox(height: 16),

          // ── Live token queue ──
          _secLabel('Live Token Queue', Icons.list_alt_outlined,
              badge: '$_activeTokens active'),
          const SizedBox(height: 8),
          _liveQueueCard(),

          const SizedBox(height: 16),

          // ── Counter status ──
          _secLabel('Counter Status', Icons.desktop_windows_outlined),
          const SizedBox(height: 8),
          _counterStatusCard(),

          const SizedBox(height: 16),

          // ── Throughput chart ──
          _secLabel('Token Throughput Today', Icons.bar_chart_outlined),
          const SizedBox(height: 8),
          _throughputCard(),

          const SizedBox(height: 16),

          // ── Service center breakdown ──
          _secLabel('Service Center Load', Icons.business_outlined),
          const SizedBox(height: 8),
          _serviceCenterCard(),

          const SizedBox(height: 16),

          // ── Weekly heatmap ──
          _secLabel('Weekly Heatmap', Icons.grid_on_outlined,
              badge: 'Tokens per hour'),
          const SizedBox(height: 8),
          _heatmapCard(),

          const SizedBox(height: 16),

          // ── Wait estimate ──
          _secLabel('Wait Time Estimate', Icons.access_time_outlined,
              badge: 'Rolling 30 min'),
          const SizedBox(height: 8),
          _waitEstimateCard(),
        ]),
      ),
    );
  }

  // ── KPI card ──────────────────────────────────
  Widget _kpi(String label, String value, IconData icon,
      Color color, String sub, bool up) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg1, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const Spacer(),
          Icon(up ? Icons.trending_up : Icons.trending_down,
              color: up ? _grn : _red, size: 13),
        ]),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(value, key: ValueKey(value),
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(color: up ? _grn : _red, fontSize: 9),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ── Live queue table ───────────────────────────
  Widget _liveQueueCard() {
    final rows = _tokens.where((t) {
      final s = (t.data() as Map)['status']?.toString() ?? '';
      return s == 'Waiting' || s == 'Serving';
    }).take(6).toList();

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          _th('Token', 2), _th('Name', 3),
          _th('Center', 3), _th('Wait', 2), _th('Status', 3),
          const Expanded(flex: 1, child: SizedBox()),
        ]),
        const SizedBox(height: 6),
        const Divider(color: _bdr, height: 1),
        const SizedBox(height: 4),

        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No active tokens',
                style: TextStyle(color: Colors.white38, fontSize: 12))),
          )
        else
          ...rows.asMap().entries.map((e) {
            final i   = e.key;
            final t   = e.value;
            final d   = t.data() as Map<String, dynamic>;
            final tok = (d['tokenNumber'] ?? 'T-${i+1}').toString();
            final nm  = (d['userName']   ?? (d['userId'] ?? '—')).toString();
            final ctr = (d['serviceCenterName'] ?? 'Center').toString();
            final st  = (d['status']    ?? 'Waiting').toString();
            final wait = i * 4 + 3;
            final nmS  = nm.length > 8 ? '${nm.substring(0,7)}…' : nm;
            final ctrS = ctr.length > 7 ? '${ctr.substring(0,6)}…' : ctr;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(flex: 2, child: Text(tok,
                    style: const TextStyle(color: _acc,
                        fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(nmS,
                    style: const TextStyle(color: Colors.white, fontSize: 11))),
                Expanded(flex: 3, child: Text(ctrS,
                    style: const TextStyle(color: Colors.white54, fontSize: 10))),
                Expanded(flex: 2, child: _miniBar(wait)),
                Expanded(flex: 3, child: _pill(st)),
                Expanded(flex: 1, child: GestureDetector(
                  onTap: () => _showTokenDetail(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                        color: _acc, borderRadius: BorderRadius.circular(5)),
                    child: const Text('▶', style: TextStyle(
                        color: Colors.white, fontSize: 8)),
                  ),
                )),
              ]),
            );
          }),

        const SizedBox(height: 8),
        const Divider(color: _bdr, height: 1),
        const SizedBox(height: 8),

        Row(children: [
          _outBtn('Call Next', _acc, () {
            if (_queues.isNotEmpty) _callNextToken(_queues.first.id);
          }),
          const SizedBox(width: 8),
          _outBtn('View all', Colors.white38,
              () => setState(() => _navIndex = 1)),
          const Spacer(),
          _outBtn('Pause', _red, () {}),
        ]),
      ],
    ));
  }

  Widget _th(String t, int flex) => Expanded(flex: flex,
      child: Text(t, style: const TextStyle(
          color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w600)));

  Widget _miniBar(int min) {
    final pct = (min / 60).clamp(0.0, 1.0);
    final c   = min < 15 ? _grn : min < 30 ? _amb : _red;
    return Row(children: [
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: pct, minHeight: 4,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation(c),
        ),
      )),
      const SizedBox(width: 3),
      Text('${min}m', style: const TextStyle(color: Colors.white24, fontSize: 8)),
    ]);
  }

  // ── Counter status ──────────────────────────────
  Widget _counterStatusCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('counters').snapshots(),
      builder: (_, snap) {
        final counters = snap.data?.docs ?? [];
        final active = counters.where((c) => c['status'] == 'active').length;

        final tiles = counters.isNotEmpty
            ? counters.take(4).map((c) {
                final d  = c.data() as Map<String, dynamic>;
                final tok = (d['currentToken'] ?? '—').toString();
                final nm  = (d['name']         ?? 'Counter').toString();
                final on  = (d['status']       ?? '') == 'active';
                return _counterTile(tok, nm, on);
              }).toList()
            : [
                _counterTile('T-104', 'Counter 1', true),
                _counterTile('T-101', 'Counter 2', true),
                _counterTile('T-067', 'Counter 3', true),
                _counterTile('—',     'Counter 4', false),
              ];

        return _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${active > 0 ? active : 3} / ${counters.isNotEmpty ? counters.length : 4} active',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: tiles,
            ),
          ],
        ));
      },
    );
  }

  Widget _counterTile(String token, String name, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bg0, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: on ? _grn.withOpacity(0.3) : _bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(token, style: TextStyle(
            color: on ? Colors.white : Colors.white24,
            fontSize: 15, fontWeight: FontWeight.bold)),
        Row(children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(
                  color: on ? _grn : Colors.white24, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(on ? 'Serving' : 'Offline',
              style: TextStyle(color: on ? _grn : Colors.white24, fontSize: 9)),
          const Spacer(),
          Text(name, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ]),
      ]),
    );
  }

  // ── Throughput bar chart ─────────────────────────
  Widget _throughputCard() {
    final data = _hourlyTokenData;
    final maxV = data.fold(1, (a, b) => a > b ? a : b);

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('8 am', style: TextStyle(color: Colors.white24, fontSize: 9)),
          Text('7 pm', style: TextStyle(color: Colors.white24, fontSize: 9)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((e) {
              final h   = ((e.value / maxV) * 52).clamp(3.0, 52.0);
              final isCurrent = e.key == (_now.hour - 8).clamp(0, 11);
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: isCurrent ? _acc : _acc.withOpacity(0.45),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                  ),
                ),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        const Text('Tokens issued per hour  (current hour highlighted)',
            style: TextStyle(color: Colors.white24, fontSize: 9)),
      ],
    ));
  }

  // ── Service center load ──────────────────────────
  Widget _serviceCenterCard() {
    // Use live Firestore data if available, else fallback
    final breakdown = _centerBreakdown.isNotEmpty
        ? _centerBreakdown
        : {'General Banking': 0, 'Loan Services': 0, 'Account Opening': 0, 'Govt. Forms': 0};

    final total = breakdown.values.fold(1, (a, b) => a + b);
    final colors = [_acc, _pur, _cyn, _grn, _amb, _red];

    return _card(child: Column(
      children: breakdown.entries.toList().asMap().entries.map((me) {
        final idx   = me.key;
        final entry = me.value;
        final pct   = entry.value / total;
        final color = colors[idx % colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 110, child: Text(entry.key,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct, minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )),
            const SizedBox(width: 6),
            SizedBox(width: 30, child: Text('${entry.value}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white38, fontSize: 11))),
          ]),
        );
      }).toList(),
    ));
  }

  // ── Weekly heatmap ───────────────────────────────
  Widget _heatmapCard() {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final heatColors = [
      const Color(0xFF1E3A5F),
      _acc.withOpacity(0.3),
      _acc.withOpacity(0.6),
      _acc,
    ];

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) => Text(d,
                style: const TextStyle(color: Colors.white38, fontSize: 9)))
                .toList()),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4, mainAxisSpacing: 4,
            childAspectRatio: 1.3,
          ),
          itemCount: 28,
          itemBuilder: (_, i) {
            final col       = i % 7;
            final row       = i ~/ 7;
            final intensity = ((col == 4 || col == 0) ? 0.9
                : col == 2 ? 0.7 : 0.4) * (0.5 + row * 0.15);
            final ci        = (intensity * 3).clamp(0, 3).toInt();
            return Container(
              decoration: BoxDecoration(
                color: heatColors[ci],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Low ', style: TextStyle(color: Colors.white38, fontSize: 9)),
          ...heatColors.map((c) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(color: c,
                  borderRadius: BorderRadius.circular(2)))),
          const Text(' High', style: TextStyle(color: Colors.white38, fontSize: 9)),
        ]),
      ],
    ));
  }

  // ── Wait estimate gauge ──────────────────────────
  Widget _waitEstimateCard() {
    // Per-center wait (from live data or fallback)
    final centers = _serviceCenters.isNotEmpty
        ? _serviceCenters.take(3).map((sc) {
            final d = sc.data() as Map<String, dynamic>;
            final nm = (d['name'] ?? 'Center').toString();
            final avg = (d['avgWaitMinutes'] ?? 0) as int;
            return MapEntry(nm, avg);
          }).toList()
        : [
            const MapEntry('General Banking', 8),
            const MapEntry('Loan Services',   22),
            const MapEntry('Account Opening', 31),
          ];

    return _card(child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gauge
        SizedBox(
          width: 100, height: 100,
          child: CustomPaint(
            painter: _GaugePainter(value: _avgWaitMins, max: 60),
            child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$_avgWaitMins', style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('min', style: TextStyle(
                  color: Colors.white38, fontSize: 10)),
            ])),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Per service center',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 10),
            ...centers.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(e.key,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis)),
                Text('${e.value} min', style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            )),
          ],
        )),
      ],
    ));
  }

  // ══════════════════════════════════════════════════════
  //  TAB 1 — QUEUE (Token management)
  // ══════════════════════════════════════════════════════
  Widget _queueTab() {
    final filtered = _filteredTokens;
    return Column(children: [
      // Filter chips
      Container(
        color: _bg1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All','Waiting','Serving','Served','Skipped'].map((f) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tokenFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _tokenFilter == f
                          ? _acc : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f, style: TextStyle(
                        color: _tokenFilter == f ? Colors.white : Colors.white38,
                        fontSize: 12,
                        fontWeight: _tokenFilter == f
                            ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
      ),

      // Count bar
      Container(
        color: _bg0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(children: [
          Text('${filtered.length} tokens',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_queues.isNotEmpty) _callNextToken(_queues.first.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _acc, borderRadius: BorderRadius.circular(8)),
              child: const Text('Call Next',
                  style: TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),

      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Column(
                mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 48, color: Colors.white12),
                SizedBox(height: 10),
                Text('No tokens', style: TextStyle(color: Colors.white38)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _tokenCard(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _tokenCard(QueryDocumentSnapshot doc) {
    final d   = doc.data() as Map<String, dynamic>;
    final tok = (d['tokenNumber']       ?? '—').toString();
    final nm  = (d['userName']          ?? '—').toString();
    final uid = (d['userId']            ?? '').toString();
    final ctr = (d['serviceCenterName'] ?? '—').toString();
    final st  = (d['status']            ?? 'Waiting').toString();
    final pos = (d['position']          ?? 0) as int;
    final ts  = d['createdAt'];
    final timeStr = ts is Timestamp
        ? '${ts.toDate().hour.toString().padLeft(2,'0')}:${ts.toDate().minute.toString().padLeft(2,'0')}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bg1, borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _tokenStatusColor(st), width: 3),
          top: const BorderSide(color: _bdr),
          right: const BorderSide(color: _bdr),
          bottom: const BorderSide(color: _bdr),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showTokenDetail(doc),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row 1: token number + name + status
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _acc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tok, style: const TextStyle(
                      color: _acc, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nm, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 13)),
                  Text(ctr, style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
                ])),
                _pill(st),
              ]),

              const SizedBox(height: 10),
              const Divider(color: _bdr, height: 1),
              const SizedBox(height: 10),

              // Row 2: meta info
              Row(children: [
                _metaChip(Icons.format_list_numbered, 'Position #$pos', _acc),
                const SizedBox(width: 8),
                _metaChip(Icons.schedule_outlined, timeStr, _amb),
                const SizedBox(width: 8),
                _metaChip(Icons.person_outline, uid.length > 8
                    ? '${uid.substring(0, 7)}…' : uid, Colors.white38),
              ]),

              const SizedBox(height: 10),

              // Row 3: action buttons
              Row(children: [
                _actionBtn('Serving', _grn, doc.id, st),
                const SizedBox(width: 6),
                _actionBtn('Served',  _acc, doc.id, st),
                const SizedBox(width: 6),
                _actionBtn('Skipped', _red, doc.id, st),
                const Spacer(),
                _actionBtn('Waiting', _amb, doc.id, st),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Flexible(child: Text(label.isEmpty ? '—' : label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10,
                fontWeight: FontWeight.w500))),
      ]),
    ));
  }

  Widget _actionBtn(String label, Color color, String id, String cur) {
    final on = cur == label;
    return GestureDetector(
      onTap: on ? null : () => _updateTokenStatus(id, label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: on ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: on ? color : color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold,
            color: on ? Colors.white : color)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 2 — USERS
  // ══════════════════════════════════════════════════════
  Widget _usersTab() {
    final filtered = _filteredUsers;
    return Column(children: [
      Container(
        color: _bg1,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQ = v.toLowerCase()),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search by name or email…',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
            suffixIcon: _searchQ.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQ = '');
                    })
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ),
      Container(
        color: _bg0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('${filtered.length} users',
              style: const TextStyle(color: Colors.white38, fontSize: 12))),
      ),
      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Text('No users found',
                style: TextStyle(color: Colors.white38)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _userCard(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _userCard(QueryDocumentSnapshot doc) {
    final uid     = doc.id;
    final name    = (doc['fullName'] ?? 'Unknown').toString();
    final email   = (doc['email']   ?? '').toString();
    final phone   = (doc['phone']   ?? '').toString();
    final role    = (doc['role']    ?? 'customer').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _bg1, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bdr),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _acc.withOpacity(0.12),
          child: Text(initial, style: const TextStyle(
              color: _acc, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(name, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(email, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(phone, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ]),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          _roleBadge(role),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 16, color: Colors.white38),
            onPressed: () => _showUserDetail(doc),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            onPressed: () => _deleteUser(uid, name),
          ),
        ]),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final color = role == 'admin' ? _pur
        : role == 'service_provider' ? _cyn : _acc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role.replaceAll('_', ' '), style: TextStyle(
          color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 3 — REPORTS
  // ══════════════════════════════════════════════════════
  Widget _reportsTab() {
    final totalTokens  = _tokens.length;
    final served       = _tokens.where((t) => t['status'] == 'Served').length;
    final waiting      = _tokens.where((t) => t['status'] == 'Waiting').length;
    final serving      = _tokens.where((t) => t['status'] == 'Serving').length;
    final skipped      = _tokens.where((t) => t['status'] == 'Skipped').length;
    final totalClamp   = totalTokens.clamp(1, 999999);

    return RefreshIndicator(
      color: _acc,
      backgroundColor: _bg1,
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Summary 2x2
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _statTile('Total Tokens',    totalTokens, _acc),
              _statTile('Served Today',    _servedToday, _grn),
              _statTile('Total Users',     _totalUsers,  _acc),
              _statTile('Active Queues',   _totalQueues, _pur),
            ],
          ),
          const SizedBox(height: 16),

          // Token status breakdown
          _secLabel('Token Status Breakdown', Icons.pie_chart_outline),
          const SizedBox(height: 8),
          _card(child: Column(children: [
            _reportBar('Waiting', waiting, totalClamp, _amb),
            const SizedBox(height: 10),
            _reportBar('Serving', serving, totalClamp, _grn),
            const SizedBox(height: 10),
            _reportBar('Served',  served,  totalClamp, _acc),
            const SizedBox(height: 10),
            _reportBar('Skipped', skipped, totalClamp, _red),
          ])),
          const SizedBox(height: 14),

          // Service center breakdown
          _secLabel('Service Center Load', Icons.business_outlined),
          const SizedBox(height: 8),
          _card(child: _centerBreakdown.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No data yet',
                      style: TextStyle(color: Colors.white38))))
              : Column(
                  children: _centerBreakdown.entries.toList().asMap().entries.map((me) {
                    final colors = [_acc, _pur, _cyn, _grn, _amb];
                    final color  = colors[me.key % colors.length];
                    final pct    = me.value.value / totalClamp;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _reportBar(me.value.key, me.value.value, totalClamp, color),
                    );
                  }).toList(),
                )),
          const SizedBox(height: 14),

          // Quick stats
          _secLabel('Quick Stats', Icons.numbers_outlined),
          const SizedBox(height: 8),
          _card(child: Column(children: [
            _qRow('Total users',        '$_totalUsers'),
            _qRow('Total tokens issued','$totalTokens'),
            _qRow('Currently waiting',  '$waiting'),
            _qRow('Being served',       '$serving'),
            _qRow('Served today',       '$_servedToday'),
            _qRow('Skipped today',      '$_skippedToday'),
            _qRow('Avg wait time',      '$_avgWaitMins min'),
            _qRow('Active queues',      '$_totalQueues'),
            _qRow('Service centers',    '${_serviceCenters.length}'),
            _qRow('Pending complaints', '$_pendingComplaints'),
            _qRow('Service rate',
                totalTokens == 0 ? '0%'
                    : '${(served / totalClamp * 100).toStringAsFixed(1)}%'),
          ])),
        ]),
      ),
    );
  }

  Widget _statTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg1, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text('$value', key: ValueKey(value),
              style: TextStyle(color: color, fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _reportBar(String label, int v, int total, Color color) {
    final pct = v / total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text('$v  (${(pct * 100).toStringAsFixed(1)}%)',
            style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct, minHeight: 7,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          )),
    ]);
  }

  Widget _qRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  //  DIALOGS
  // ══════════════════════════════════════════════════════
  void _showTokenDetail(QueryDocumentSnapshot doc) {
    final d  = doc.data() as Map<String, dynamic>;
    final st = (d['status'] ?? 'Waiting').toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20,
            20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 14),
          Row(children: [
            const Text('Token Details', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            _pill(st),
          ]),
          const SizedBox(height: 12),
          _dlgRow(Icons.confirmation_number_outlined, 'Token',    d['tokenNumber']),
          _dlgRow(Icons.person_outline,               'User',     d['userName']),
          _dlgRow(Icons.business_outlined,            'Center',   d['serviceCenterName']),
          _dlgRow(Icons.format_list_numbered,         'Position', d['position']?.toString()),
          _dlgRow(Icons.access_time_outlined,         'Created',  _fmtTs(d['createdAt'])),
          _dlgRow(Icons.check_circle_outline,         'Served',   _fmtTs(d['servedAt'])),
          const SizedBox(height: 14),
          const Text('Update Status', style: TextStyle(
              color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
              children: ['Waiting','Serving','Served','Skipped'].map((s) =>
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateTokenStatus(doc.id, s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _tokenStatusColor(s).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _tokenStatusColor(s).withOpacity(0.4)),
                    ),
                    child: Text(s, style: TextStyle(
                        color: _tokenStatusColor(s), fontSize: 12,
                        fontWeight: FontWeight.bold)),
                  ),
                )).toList()),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showUserDetail(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text((doc['fullName'] ?? 'User').toString(),
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
          _dlgRow(Icons.email_outlined,               'Email',   doc['email']),
          _dlgRow(Icons.phone_outlined,               'Phone',   doc['phone']),
          _dlgRow(Icons.cake_outlined,                'DOB',     doc['dob']),
          _dlgRow(Icons.wc_outlined,                  'Gender',  doc['gender']),
          _dlgRow(Icons.home_outlined,                'Address', doc['address']),
          _dlgRow(Icons.admin_panel_settings_outlined,'Role',    doc['role']),
        ])),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Colors.white38)))],
      ),
    );
  }

  String _fmtTs(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  // ══════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _bg1, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _bdr),
    ),
    child: child,
  );

  Widget _secLabel(String title, IconData icon, {String? badge}) {
    return Row(children: [
      Icon(icon, color: _acc, size: 16),
      const SizedBox(width: 7),
      Text(title, style: const TextStyle(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      if (badge != null) ...[
        const Spacer(),
        Text(badge, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    ]);
  }

  Widget _pill(String status) {
    final color = _tokenStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _outBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _dlgRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 14, color: _acc),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(child: Text((value ?? '—').toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
    );
  }

  Color _tokenStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'waiting': return _amb;
      case 'serving': return _grn;
      case 'served':  return _acc;
      case 'skipped': return _red;
      default:        return Colors.white38;
    }
  }

  Color _urgencyColor(String u) {
    switch (u.toLowerCase()) {
      case 'high':   return _red;
      case 'medium': return _amb;
      default:       return _grn;
    }
  }
}

// ══════════════════════════════════════════════════════
//  GAUGE PAINTER
// ══════════════════════════════════════════════════════
class _GaugePainter extends CustomPainter {
  final int value, max;
  const _GaugePainter({required this.value, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width / 2) - 8;

    final bg = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    const start   = 3.14159 * 0.75;
    const fullSwp = 3.14159 * 1.5;
    final sweep   = fullSwp * (value / max.clamp(1, 9999));

    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, fullSwp, false, bg);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.max != max;
}