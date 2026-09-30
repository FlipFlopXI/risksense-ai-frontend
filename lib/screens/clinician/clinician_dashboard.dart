import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/models/mock_data.dart';
import 'package:medguide/screens/clinician/patient_detail_screen.dart';
import 'package:medguide/screens/shared/data_input_screen.dart';
import 'package:medguide/screens/auth/login_screen.dart';

class ClinicianDashboard extends StatefulWidget {
  const ClinicianDashboard({super.key});

  @override
  State<ClinicianDashboard> createState() => _ClinicianDashboardState();
}

class _ClinicianDashboardState extends State<ClinicianDashboard> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(onNavigate: (i) => setState(() => _currentIndex = i)),
          _PatientsTab(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
          ),
          const DataInputScreen(),
          _ProfileTab(onSignOut: _signOut),
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
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Analysis',
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

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text(MockUser.clinicianName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text('Clinician • General Practice',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Divider(),
            _drawerItem(Icons.dashboard_outlined, 'Dashboard', () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            }),
            _drawerItem(Icons.people_outline_rounded, 'Patients', () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            }),
            _drawerItem(Icons.analytics_outlined, 'Run Analysis', () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            }),
            const Spacer(),
            const Divider(),
            _drawerItem(Icons.logout_rounded, 'Sign Out', () {
              Navigator.pop(context);
              _signOut();
            }, color: AppColors.danger),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryBlue, size: 22),
      title: Text(label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          )),
      onTap: onTap,
      dense: true,
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const _DashboardTab({required this.onNavigate});

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
        title: const Text('Clinician Dashboard'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Clinician Dashboard'),
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
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Welcome, ',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  TextSpan(
                    text: MockUser.clinicianName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'DMSans',
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Thursday, February 19, 2026',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                  title: 'High Risk Alerts',
                  value: '8',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  subtitle: '3 require review',
                ),
                StatCard(
                  title: 'Total Patients',
                  value: '142',
                  icon: Icons.people_rounded,
                  color: AppColors.primaryBlue,
                  subtitle: '+4 this week',
                ),
                StatCard(
                  title: 'Predictions Today',
                  value: '24',
                  icon: Icons.analytics_rounded,
                  color: AppColors.teal,
                  subtitle: 'Across all patients',
                ),
                StatCard(
                  title: 'Drug Flags',
                  value: '3',
                  icon: Icons.medication_liquid_outlined,
                  color: AppColors.amber,
                  subtitle: 'Require attention',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'High Risk Alerts',
              actionLabel: 'View All',
              onAction: () => onNavigate(1),
            ),
            const SizedBox(height: 12),
            ...mockPatients
                .where((p) => p['riskLevel'] == 'High')
                .map((p) => _PatientAlertCard(
                      patient: p,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(patient: p)),
                      ),
                    )),
            const SizedBox(height: 12),
            const SectionHeader(title: 'Recent Cases'),
            const SizedBox(height: 12),
            ...mockPatients.take(3).map((p) => _RecentPatientCard(
                  patient: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => PatientDetailScreen(patient: p)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Patients Tab ─────────────────────────────────────────────────────────────
class _PatientsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _PatientsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = mockPatients
        .where((p) => (p['name'] as String)
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Patients'),
        actions: const [
          SecureBadge(),
          ScreenHelpButton(topic: 'Patients'),
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
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search patients by name or ID...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _PatientListCard(
                patient: filtered[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientDetailScreen(patient: filtered[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _ProfileTab({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          const MedAppBar(title: 'My Profile', helpTopic: 'Clinician Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(MockUser.clinicianName,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('Clinician • General Practice',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  const SecureBadge(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...[
              [Icons.badge_outlined, 'License Number', 'MC-2024-88412'],
              [
                Icons.local_hospital_outlined,
                'Institution',
                'City Medical Centre'
              ],
              [Icons.email_outlined, 'Email', 'dr.osei@clinic.com'],
              [Icons.history_outlined, 'Last Login', 'Feb 19, 2026 at 09:14'],
            ].map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(item[0] as IconData,
                        size: 20, color: AppColors.primaryBlue),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item[1] as String,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        Text(item[2] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.danger),
                label: const Text('Sign Out',
                    style: TextStyle(color: AppColors.danger)),
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Patient Cards ────────────────────────────────────────────────────────────
class _PatientAlertCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  const _PatientAlertCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient['name'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(patient['condition'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.danger)),
                ],
              ),
            ),
            Text(patient['id'],
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _RecentPatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  const _RecentPatientCard({required this.patient, required this.onTap});

  Color get _levelColor {
    switch (patient['riskLevel']) {
      case 'High':
        return AppColors.riskHigh;
      case 'Moderate':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Text(
                (patient['name'] as String).substring(0, 1),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient['name'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('Age ${patient['age']} • ${patient['id']}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(patient['riskLevel'],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _levelColor)),
                ),
                const SizedBox(height: 3),
                Text(patient['lastVisit'],
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _PatientListCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;
  const _PatientListCard({required this.patient, required this.onTap});

  Color get _levelColor {
    switch (patient['riskLevel']) {
      case 'High':
        return AppColors.riskHigh;
      case 'Moderate':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  (patient['name'] as String).substring(0, 1),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _levelColor),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient['name'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(patient['condition'],
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(patient['id'],
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(patient['riskLevel'],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _levelColor)),
                ),
                const SizedBox(height: 3),
                Text(patient['lastVisit'],
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
