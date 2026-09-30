import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/models/mock_data.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/admin/admin_profile_screen.dart';
import 'package:medguide/services/api_client.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

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
    return Scaffold(
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _OverviewTab(onNavigate: (i) => setState(() => _currentIndex = i)),
          const _UserManagementTab(),
          const _AuditLogsTab(),
          _ModelTab(onSnackBar: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(msg), backgroundColor: AppColors.primaryBlue),
            );
          }),
          const AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
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
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.teal],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(MockUser.adminName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text('System Administrator',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(),
            _item(Icons.dashboard_outlined, 'Overview', () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            }),
            _item(Icons.manage_accounts_outlined, 'User Management', () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            }),
            _item(Icons.receipt_long_outlined, 'Audit Logs', () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            }),
            _item(Icons.memory_outlined, 'Model Management', () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            }),
            _item(Icons.person_outline_rounded, 'Profile', () {
              setState(() => _currentIndex = 4);
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
class _OverviewTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const _OverviewTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryBlue),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryBlue, Color(0xFF0D5A8B)],
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
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 26),
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
                      Text('MedSurrogate AI Platform v1.0',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: const [
                StatCard(
                  title: 'Total Users',
                  value: '247',
                  icon: Icons.people_rounded,
                  color: AppColors.primaryBlue,
                  subtitle: '+12 this week',
                ),
                StatCard(
                  title: 'Clinicians',
                  value: '38',
                  icon: Icons.medical_services_rounded,
                  color: AppColors.teal,
                  subtitle: 'Active accounts',
                ),
                StatCard(
                  title: 'Predictions',
                  value: '1,842',
                  icon: Icons.analytics_rounded,
                  color: AppColors.success,
                  subtitle: 'This month',
                ),
                StatCard(
                  title: 'Security Events',
                  value: '2',
                  icon: Icons.security_rounded,
                  color: AppColors.amber,
                  subtitle: 'Pending review',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Activity'),
            const SizedBox(height: 12),
            ...mockAuditLogs.take(3).map((log) => _AuditLogCard(log: log)),
          ],
        ),
      ),
    );
  }
}

// ─── User Management Tab ──────────────────────────────────────────────────────
class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context) {
    final users = [
      {
        'name': 'Sarah Mitchell',
        'email': 'sarah.m@email.com',
        'role': 'Patient',
        'status': 'Active'
      },
      {
        'name': 'Dr. James Osei',
        'email': 'dr.osei@clinic.com',
        'role': 'Clinician',
        'status': 'Active'
      },
      {
        'name': 'Marcus Thompson',
        'email': 'marcus.t@email.com',
        'role': 'Patient',
        'status': 'Active'
      },
      {
        'name': 'Dr. Li Chen',
        'email': 'dr.chen@clinic.com',
        'role': 'Clinician',
        'status': 'Active'
      },
      {
        'name': 'Aisha Patel',
        'email': 'aisha.p@email.com',
        'role': 'Patient',
        'status': 'Suspended'
      },
    ];

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
          const Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              itemBuilder: (context, i) => _UserCard(user: users[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Audit Logs Tab ───────────────────────────────────────────────────────────
class _AuditLogsTab extends StatelessWidget {
  const _AuditLogsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Audit Logs'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Audit Logs'),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockAuditLogs.length,
        itemBuilder: (context, i) => _AuditLogCard(log: mockAuditLogs[i]),
      ),
    );
  }
}

// ─── Model Tab ────────────────────────────────────────────────────────────────
class _ModelTab extends StatelessWidget {
  final void Function(String) onSnackBar;
  const _ModelTab({required this.onSnackBar});

  @override
  Widget build(BuildContext context) {
    final models = [
      {
        'name': 'Diabetes Risk Model',
        'version': 'v2.3.1',
        'accuracy': '87.4%',
        'deployed': 'Feb 1, 2026',
        'status': 'Active',
      },
      {
        'name': 'Heart Disease Model',
        'version': 'v1.8.0',
        'accuracy': '83.1%',
        'deployed': 'Jan 15, 2026',
        'status': 'Active',
      },
      {
        'name': 'Drug Response Model',
        'version': 'v1.2.4',
        'accuracy': '79.6%',
        'deployed': 'Dec 20, 2025',
        'status': 'Active',
      },
      {
        'name': 'Diabetes Risk Model',
        'version': 'v2.3.2-beta',
        'accuracy': '88.9%',
        'deployed': 'Feb 18, 2026',
        'status': 'Staging',
      },
    ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.primaryBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All model versions are tracked and audited. Only one version may be active per condition.',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...models.map((m) => _ModelCard(model: m, onSnackBar: onSnackBar)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Sub-Widgets ───────────────────────────────────────────────────────
class _AuditLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _AuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.receipt_long_outlined,
                size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['action'],
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(log['user'],
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Text(log['timestamp'],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(width: 10),
                    const Icon(Icons.language_rounded,
                        size: 11, color: AppColors.textLight),
                    const SizedBox(width: 3),
                    Text(log['ip'],
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
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
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user['status'] == 'Active';
    final roleColor =
        user['role'] == 'Clinician' ? AppColors.teal : AppColors.primaryBlue;

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
              (user['name'] as String).substring(0, 1),
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: roleColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'],
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(user['email'],
                    style: const TextStyle(
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
                child: Text(user['role'],
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
                  user['status'],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final Map<String, dynamic> model;
  final void Function(String) onSnackBar;
  const _ModelCard({required this.model, required this.onSnackBar});

  @override
  Widget build(BuildContext context) {
    final isActive = model['status'] == 'Active';
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
                child: Text(model['name'],
                    style: const TextStyle(
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
                  model['status'],
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
              _stat('Version', model['version']),
              _stat('Accuracy', model['accuracy']),
              _stat('Deployed', model['deployed']),
            ],
          ),
          if (model['status'] == 'Staging') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () =>
                    onSnackBar('Model deployment requires admin approval.'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('Promote to Production'),
              ),
            ),
          ],
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
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
