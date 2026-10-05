import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/mess_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final messProvider = context.watch<MessProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                      ),
                      if (user?.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.phone!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preferences
          const Text('Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: Text(context.tr('language')),
                  subtitle: Text(localeProvider.isBengali ? 'বাংলা' : 'English'),
                  trailing: Switch(
                    value: localeProvider.isBengali,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) => localeProvider.toggleLocale(),
                  ),
                ),
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.apartment_rounded, color: AppColors.secondary),
                  title: const Text('Mess Name'),
                  subtitle: Text(messProvider.currentMess?.name ?? 'Swapno Neer'),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Legal & Help
          const Text('About & Legal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.neutral),
                  title: Text(context.tr('privacy_policy')),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.tr('privacy_policy')),
                        content: const Text(
                          'MessHub collects user email, name, and mess records exclusively for calculating shared mess finances. We do not sell or monetize personal or financial data.',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.neutral),
                  title: Text(context.tr('terms_of_service')),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.tr('terms_of_service')),
                        content: const Text(
                          'MessHub is designed for university students, bachelors, and shared-flat residents in Bangladesh. All calculations follow Bangladesh bachelor mess conventions.',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/logo.png', width: 26, height: 26, fit: BoxFit.cover),
                  ),
                  title: Text(context.tr('version')),
                  subtitle: const Text('1.0.0 (Production Release)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: Text(context.tr('logout')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negativeBg,
              foregroundColor: AppColors.negative,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
