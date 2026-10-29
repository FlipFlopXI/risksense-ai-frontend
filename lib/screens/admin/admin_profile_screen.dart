import 'package:medguide/widgets/app_id_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/widgets/shared_widgets.dart';
import 'package:medguide/screens/auth/login_screen.dart';
import 'package:medguide/screens/shared/settings_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<Map<String, dynamic>> _load() async =>
      Map<String, dynamic>.from(await ApiClient.instance.get('/admin/me'));
  Future<void> _signOut() async {
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _showAdminId(String id) =>
      showAppIdDialog(context, title: 'Admin ID', id: id);

  String _timestamp(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return parsed == null
        ? 'No Activity Recorded'
        : DateFormat('d MMM yyyy, HH:mm').format(parsed);
  }

  String _action(dynamic value) {
    if (value is! Map) return 'No Administrative Action Recorded';
    final words = value['action'].toString().toLowerCase().split('_');
    return words
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => Scaffold(
              backgroundColor: AppColors.background,
              appBar: MedAppBar(title: 'Admin Profile', actions: [
                IconButton(
                    tooltip: 'Settings',
                    icon: Icon(Icons.settings_outlined,
                        color: AppColors.primaryBlue),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const SettingsScreen(role: 'admin'))))
              ]),
              body: FutureBuilder<Map<String, dynamic>>(
                  future: _profile,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return Center(
                          child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => _profile = _load()),
                              child: const Text('Retry Profile')));
                    final data = snapshot.data!;
                    final lastAction = data['last_action'];
                    return RefreshIndicator(
                        onRefresh: () async {
                          final next = _load();
                          setState(() => _profile = next);
                          await next;
                        },
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        AppColors.heroStart,
                                        AppColors.heroEnd
                                      ]),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Row(children: [
                                    const CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.white24,
                                        child: Icon(
                                            Icons.admin_panel_settings_rounded,
                                            color: Colors.white,
                                            size: 30)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          const Text('System Administrator',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700)),
                                          Text(data['email'].toString(),
                                              style: const TextStyle(
                                                  color: Colors.white70))
                                        ]))
                                  ])),
                              const SizedBox(height: 16),
                              Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                      color: AppColors.cardWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: AppColors.border)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Account And Activity',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall),
                                        const Divider(height: 24),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text('Admin ID',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .textSecondary))),
                                              InkWell(
                                                  onTap: () => _showAdminId(
                                                      data['admin_id']
                                                          .toString()),
                                                  child: Text('Tap To View ID',
                                                      style: TextStyle(
                                                          color: AppColors
                                                              .primaryBlue,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          decorationColor: AppColors.primaryBlue,
                                                          decorationThickness: 2))),
                                            ])),
                                        InfoRow(
                                            label: 'Status',
                                            value: data['is_active'] == true
                                                ? 'Active'
                                                : 'Inactive'),
                                        InfoRow(
                                            label: 'Last Login',
                                            value: _timestamp(
                                                data['last_login_at'])),
                                        InfoRow(
                                            label: 'Last Action',
                                            value: _action(lastAction)),
                                        if (lastAction is Map)
                                          InfoRow(
                                              label: 'Action Time',
                                              value: _timestamp(
                                                  lastAction['performed_at'])),
                                      ])),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                  onPressed: _signOut,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Sign Out'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side:
                                          BorderSide(color: AppColors.danger))),
                            ]));
                  }),
            ));
  }
}
