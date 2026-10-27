import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/admin/admin_profile_screen.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/widgets/app_error_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final _epochs = List<int>.filled(5, 0);
  void _navigate(int index) => setState(() {
        _currentIndex = index;
        _epochs[index]++;
      });

  Future<void> _signOut() async {
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _OverviewTab(key: ValueKey(_epochs[0]), onNavigate: _navigate),
          _UserManagementTab(key: ValueKey(_epochs[1])),
          _AuditLogsTab(key: ValueKey(_epochs[2])),
          _ModelTab(
              key: ValueKey(_epochs[3]),
              onError: (msg) => showAppErrorDialog(context, msg)),
          AdminProfileScreen(key: ValueKey(_epochs[4])),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _navigate,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textLight,
            backgroundColor: AppColors.cardWhite,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_accounts_outlined),
                activeIcon: Icon(Icons.manage_accounts_rounded),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Audit Logs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.memory_outlined),
                activeIcon: Icon(Icons.memory_rounded),
                label: 'Models',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.heroStart, AppColors.heroEnd],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text('System Administrator',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('System Administrator',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(),
            _item(Icons.dashboard_outlined, 'Overview', () {
              _navigate(0);
              Navigator.pop(context);
            }),
            _item(Icons.manage_accounts_outlined, 'User Management', () {
              _navigate(1);
              Navigator.pop(context);
            }),
            _item(Icons.receipt_long_outlined, 'Audit Logs', () {
              _navigate(2);
              Navigator.pop(context);
            }),
            _item(Icons.memory_outlined, 'Model Management', () {
              _navigate(3);
              Navigator.pop(context);
            }),
            _item(Icons.person_outline_rounded, 'Profile', () {
              _navigate(4);
              Navigator.pop(context);
            }),
            const Spacer(),
            const Divider(),
            _item(Icons.logout_rounded, 'Sign Out', () {
              Navigator.pop(context);
              _signOut();
            }, color: AppColors.danger),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryBlue, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
      onTap: onTap,
      dense: true,
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final void Function(int) onNavigate;
  const _OverviewTab({super.key, required this.onNavigate});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late Future<List<dynamic>> _data = _load();
  Future<List<dynamic>> _load() => Future.wait([
        ApiClient.instance.get('/admin/metrics'),
        ApiClient.instance.get('/admin/audit', query: {'limit': 3}),
      ]);
  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppColors.primaryBlue),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Admin Console'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Admin Console'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: Text(
                          'Unable to load admin overview. Tap to retry: ${snapshot.error}')));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final metrics = Map<String, dynamic>.from(snapshot.data![0] as Map);
            final recent = (snapshot.data![1] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            return RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.heroStart, AppColors.heroEnd],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('System Administrator',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text('RiskSense AI Administration',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white60)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 174),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            compact: true,
                            title: 'Total Users',
                            value: '${metrics['total_users'] ?? 0}',
                            icon: Icons.people_rounded,
                            color: AppColors.primaryBlue,
                            subtitle: 'Registered accounts',
                          ),
                          StatCard(
                            compact: true,
                            title: 'Clinicians',
                            value: '${metrics['clinician_count'] ?? 0}',
                            icon: Icons.medical_services_rounded,
                            color: AppColors.teal,
                            subtitle: 'Registered clinicians',
                          ),
                          StatCard(
                            compact: true,
                            title: 'Predictions',
                            value: '${metrics['prediction_count'] ?? 0}',
                            icon: Icons.analytics_rounded,
                            color: AppColors.success,
                            subtitle: 'All time',
                          ),
                          StatCard(
                            compact: true,
                            title: 'Audit Events',
                            value: '${metrics['audit_event_count'] ?? 0}',
                            icon: Icons.security_rounded,
                            color: AppColors.amber,
                            subtitle: 'All recorded events',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                          title: 'Recent Activity',
                          actionLabel: 'View All',
                          onAction: () => widget.onNavigate(2)),
                      const SizedBox(height: 12),
                      if (recent.isEmpty)
                        const Text('No audit activity recorded.'),
                      ...recent.map((log) => _AuditLogCard(log: log)),
                    ],
                  ),
                ));
          }),
    );
  }
}

// ─── User Management Tab ──────────────────────────────────────────────────────
class _UserManagementTab extends StatefulWidget {
  const _UserManagementTab({super.key});
  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  final _search = TextEditingController();
  String _role = 'All Roles', _status = 'All Statuses';
  bool _oldest = false;
  bool _hasMore = true;
  late Future<List<Map<String, dynamic>>> _users = _load();

  Future<List<Map<String, dynamic>>> _load({int offset = 0}) async =>
      (await ApiClient.instance.get('/admin/users', query: {
        'limit': 200,
        'offset': offset,
        'oldest_first': _oldest,
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        if (_role != 'All Roles') 'role': _role.toLowerCase(),
        if (_status != 'All Statuses') 'is_active': _status == 'Active',
      }) as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _users = next;
      _hasMore = true;
    });
    await next;
  }

  Future<void> _more() async {
    try {
      final current = await _users;
      final next = await _load(offset: current.length);
      if (mounted)
        setState(() {
          _users = Future.value([...current, ...next]);
          _hasMore = next.length == 200;
        });
    } on ApiException catch (error) {
      if (mounted) await showAppErrorDialog(context, error.message);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    var role = _role, status = _status, oldest = _oldest;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filter Users',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 14),
                          Wrap(spacing: 8, children: [
                            for (final value in [
                              'All Roles',
                              'Patient',
                              'Clinician',
                              'Admin'
                            ])
                              ChoiceChip(
                                  label: Text(value),
                                  selected: role == value,
                                  onSelected: (_) => update(() => role = value))
                          ]),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: [
                            for (final value in [
                              'All Statuses',
                              'Active',
                              'Suspended'
                            ])
                              ChoiceChip(
                                  label: Text(value),
                                  selected: status == value,
                                  onSelected: (_) =>
                                      update(() => status = value))
                          ]),
                          SwitchListTile(
                              title: const Text('Oldest First'),
                              value: oldest,
                              onChanged: (v) => update(() => oldest = v)),
                          Row(children: [
                            TextButton(
                                onPressed: () {
                                  update(() {
                                    role = 'All Roles';
                                    status = 'All Statuses';
                                    oldest = false;
                                  });
                                },
                                child: const Text('Reset')),
                            const Spacer(),
                            FilledButton(
                                onPressed: () {
                                  _role = role;
                                  _status = status;
                                  _oldest = oldest;
                                  _refresh();
                                  Navigator.pop(sheet);
                                },
                                child: const Text('Apply')),
                          ]),
                        ],
                      )),
                )));
  }

  Future<void> _setActive(Map<String, dynamic> user) async {
    final active = user['is_active'] == true;
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(active ? 'Suspend User?' : 'Restore User?'),
              content: Text(
                  '${user['email']} will be ${active ? 'suspended' : 'restored'}.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: Text(active ? 'Suspend' : 'Restore'))
              ],
            ));
    if (approved != true) return;
    try {
      await ApiClient.instance
          .post('/admin/users/${user['id']}/${active ? 'suspend' : 'restore'}');
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) await showAppErrorDialog(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('User Management'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'User Management'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                  child: TextField(
                controller: _search,
                onSubmitted: (_) => _refresh(),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              )),
              IconButton.filledTonal(
                  onPressed: _filters,
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filter Users')
            ]),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _users,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(
                        child: TextButton(
                            onPressed: _refresh,
                            child: Text(
                                'Unable to load users. Tap to retry: ${snapshot.error}')));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!;
                  return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.isEmpty
                            ? 1
                            : users.length +
                                (_hasMore && users.length % 200 == 0 ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (users.isEmpty)
                            return const Center(
                                child: Text('No users match these filters.'));
                          if (i == users.length)
                            return TextButton(
                                onPressed: _more,
                                child: const Text('Load More Users'));
                          return _UserCard(
                              user: users[i],
                              onAction: () => _setActive(users[i]));
                        },
                      ));
                }),
          ),
        ],
      ),
    );
  }
}

// ─── Audit Logs Tab ───────────────────────────────────────────────────────────
class _AuditLogsTab extends StatefulWidget {
  const _AuditLogsTab({super.key});
  @override
  State<_AuditLogsTab> createState() => _AuditLogsTabState();
}

class _AuditLogsTabState extends State<_AuditLogsTab> {
  final ScrollController _scrollController = ScrollController();
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _action, _status;
  bool _oldest = false;
  bool _hasMore = true;
  late Future<List<Map<String, dynamic>>> _events = _load();
  late Future<List<String>> _actions = _loadActions();
  Future<List<Map<String, dynamic>>> _load({int offset = 0}) async =>
      (await ApiClient.instance.get('/admin/audit', query: {
        'limit': 500,
        'offset': offset,
        'oldest_first': _oldest,
        if (_action != null) 'action': _action,
        if (_status != null) 'status': _status,
      }) as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
  Future<List<String>> _loadActions() async =>
      (await ApiClient.instance.get('/admin/audit/actions') as List)
          .map((v) => v.toString())
          .toList();
  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _events = next;
      _hasMore = true;
    });
    await next;
  }

  Future<void> _more() async {
    try {
      final current = await _events;
      final next = await _load(offset: current.length);
      if (mounted)
        setState(() {
          _events = Future.value([...current, ...next]);
          _hasMore = next.length == 500;
        });
    } on ApiException catch (error) {
      if (mounted) await showAppErrorDialog(context, error.message);
    }
  }

  Future<void> _filters() async {
    var action = _action, status = _status, oldest = _oldest;
    List<String> actions;
    try {
      actions = await _actions;
    } on ApiException catch (error) {
      if (mounted) await showAppErrorDialog(context, error.message);
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filter Audit Logs',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue:
                                  actions.contains(action) ? action : '',
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Action'),
                              items: [
                                const DropdownMenuItem(
                                    value: '', child: Text('All Actions')),
                                for (final value in actions)
                                  DropdownMenuItem(
                                      value: value,
                                      child: Text(value.replaceAll('_', ' '),
                                          overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: (v) =>
                                  update(() => action = v == '' ? null : v)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, children: [
                            for (final value in <String?>[
                              null,
                              'success',
                              'failure'
                            ])
                              ChoiceChip(
                                  label: Text(value == null
                                      ? 'All Statuses'
                                      : '${value[0].toUpperCase()}${value.substring(1)}'),
                                  selected: status == value,
                                  onSelected: (_) =>
                                      update(() => status = value))
                          ]),
                          SwitchListTile(
                              title: const Text('Oldest First'),
                              value: oldest,
                              onChanged: (v) => update(() => oldest = v)),
                          Row(children: [
                            TextButton(
                                onPressed: () => update(() {
                                      action = null;
                                      status = null;
                                      oldest = false;
                                    }),
                                child: const Text('Reset')),
                            const Spacer(),
                            FilledButton(
                                onPressed: () {
                                  _action = action;
                                  _status = status;
                                  _oldest = oldest;
                                  _refresh();
                                  Navigator.pop(sheet);
                                },
                                child: const Text('Apply'))
                          ]),
                        ],
                      )),
                )));
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
              onPressed: _filters,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Filter Audit Logs'),
          const ScreenHelpButton(topic: 'Audit Logs'),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _events,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: Text(
                          'Unable to load audit logs. Tap to retry: ${snapshot.error}')));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final events = snapshot.data!;
            return RefreshIndicator(
                onRefresh: _refresh,
                child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    trackVisibility: false,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: events.isEmpty
                          ? 1
                          : events.length +
                              (_hasMore && events.length % 500 == 0 ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (events.isEmpty)
                          return const Center(
                              child:
                                  Text('No audit events match these filters.'));
                        if (i == events.length)
                          return TextButton(
                              onPressed: _more,
                              child: const Text('Load More Events'));
                        return _AuditLogCard(log: events[i]);
                      },
                    )));
          }),
    );
  }
}

// ─── Model Tab ────────────────────────────────────────────────────────────────
class _ModelTab extends StatefulWidget {
  final void Function(String) onError;
  const _ModelTab({super.key, required this.onError});
  @override
  State<_ModelTab> createState() => _ModelTabState();
}

class _ModelTabState extends State<_ModelTab> {
  late Future<List<Map<String, dynamic>>> _models = _load();
  late Future<Map<String, dynamic>> _drugStatus = _loadDrugStatus();
  Future<List<Map<String, dynamic>>> _load() async =>
      (await ApiClient.instance.get('/admin/models') as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
  Future<Map<String, dynamic>> _loadDrugStatus() async =>
      Map<String, dynamic>.from(
          await ApiClient.instance.get('/admin/drug-assistant/status'));
  Future<void> _refresh() async {
    final next = _load(), drug = _loadDrugStatus();
    setState(() {
      _models = next;
      _drugStatus = drug;
    });
    await next;
  }

  Future<void> _toggle(Map<String, dynamic> model) async {
    final active = model['is_active'] == true;
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(active ? 'Pause Model?' : 'Resume Model?'),
              content: Text(
                  '${model['name']} will be ${active ? 'paused' : 'resumed'}.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: Text(active ? 'Pause' : 'Resume'))
              ],
            ));
    if (approved != true) return;
    try {
      await ApiClient.instance.post(
          '/admin/models/${model['id']}/${active ? 'suspend' : 'resume'}');
      await _refresh();
    } on ApiException catch (error) {
      widget.onError(error.message);
    }
  }

  Future<void> _contact() async {
    final uri = Uri(scheme: 'mailto', path: 'shivenreddyxi@gmail.com');
    if (!await launchUrl(uri) && mounted)
      widget.onError('No email app is available on this device.');
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Model Management'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Model Management'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _models,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                  child: TextButton(
                      onPressed: _refresh,
                      child: Text(
                          'Unable to load models. Tap to retry: ${snapshot.error}')));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final models = snapshot.data!;
            return RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.primaryBlue, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Model status comes from the registry. Activation verifies the supported model artifact.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (models.isEmpty)
                        const Text('No model records are registered.'),
                      ...models.map((m) =>
                          _ModelCard(model: m, onToggle: () => _toggle(m))),
                      FutureBuilder<Map<String, dynamic>>(
                          future: _drugStatus,
                          builder: (context, status) {
                            if (status.hasError)
                              return const ListTile(
                                  title: Text('Drug Assistant Runtime'),
                                  subtitle: Text(
                                      'Runtime status unavailable. Pull to refresh.'));
                            if (!status.hasData)
                              return const LinearProgressIndicator();
                            final info = status.data!;
                            return Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Drug Assistant Runtime',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                          const SizedBox(height: 6),
                                          Text(
                                              'Status: ${info['runtime_status']} • Integrity: ${info['artifact_integrity_status']}'),
                                          Text(
                                              'Catalogue: ${info['catalogue_medication_count']} medications • Published evidence: ${info['reviewed_evidence_count']} records'),
                                          Text(
                                              'Evidence-gated assistant; managed separately from prediction models.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary)),
                                        ])));
                          }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                          onPressed: _contact,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Contact Developer')),
                    ],
                  ),
                ));
          }),
    );
  }
}

// ─── Shared Sub-Widgets ───────────────────────────────────────────────────────
class _AuditLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _AuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final action =
        log['action']?.toString().replaceAll('_', ' ') ?? 'Unknown Action';
    final timestamp =
        DateTime.tryParse(log['created_at']?.toString() ?? '')?.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                    log['user_email']?.toString() ??
                        log['user_id']?.toString() ??
                        'System',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(
                            timestamp == null
                                ? 'Time unavailable'
                                : DateFormat.yMMMd().add_jm().format(timestamp),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textLight))),
                    const SizedBox(width: 10),
                    Icon(Icons.language_rounded,
                        size: 11, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Flexible(
                        child: Text(
                            log['ip_address']?.toString() ??
                                log['status']?.toString() ??
                                'Recorded',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textLight))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onAction;
  const _UserCard({required this.user, required this.onAction});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isActive = user['is_active'] == true;
    final role = user['role']?.toString() ?? 'unknown';
    final roleLabel = '${role[0].toUpperCase()}${role.substring(1)}';
    final name =
        user['display_name']?.toString() ?? user['email']?.toString() ?? 'User';
    final roleColor =
        role == 'clinician' ? AppColors.teal : AppColors.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: roleColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(user['email']?.toString() ?? 'No email',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(roleLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleColor)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.danger),
                ),
              ),
              TextButton(
                  onPressed: onAction,
                  child: Text(isActive ? 'Suspend' : 'Restore',
                      style: TextStyle(
                          color: isActive
                              ? AppColors.danger
                              : AppColors.success))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final Map<String, dynamic> model;
  final VoidCallback onToggle;
  const _ModelCard({required this.model, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isActive = model['is_active'] == true;
    final target = model['prediction_target']?.toString() ?? '';
    final resumable = target == 'diabetes_risk' || target == 'heart_disease';
    final created =
        DateTime.tryParse(model['created_at']?.toString() ?? '')?.toLocal();
    final accuracy = model['accuracy'] is num
        ? '${((model['accuracy'] as num).toDouble() * 100).toStringAsFixed(1)}%'
        : 'Unavailable';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(model['name']?.toString() ?? 'Unnamed Model',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Paused',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('Version', model['version']?.toString() ?? 'Unknown'),
              _stat('Accuracy', accuracy),
              _stat(
                  'Registered',
                  created == null
                      ? 'Unknown'
                      : DateFormat.yMMMd().format(created)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              'Target: ${target.replaceAll('_', ' ')} • ${model['algorithm'] ?? 'Algorithm unavailable'}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (model['dataset_name'] != null)
            Text('Dataset: ${model['dataset_name']}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
              model['accuracy_source']?.toString() ??
                  'No verified held-out accuracy for this model version.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isActive || resumable ? onToggle : null,
                icon: Icon(isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                label: Text(isActive
                    ? 'Pause Model'
                    : resumable
                        ? 'Resume Model'
                        : 'Resume Unavailable'),
                style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isActive ? AppColors.danger : AppColors.teal,
                    side: BorderSide(
                        color: isActive ? AppColors.danger : AppColors.teal)),
              )),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
