import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/translations.dart';
import 'dashboard/dashboard_screen.dart';
import 'bills/bills_screen.dart';
import 'expenses/expenses_screen.dart';
import 'meals/meals_screen.dart';
import 'members/members_screen.dart';
import 'settlements/settlement_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    BillsScreen(),
    ExpensesScreen(),
    MealsScreen(),
    _MoreMenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: context.tr('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long_rounded),
            label: context.tr('bills'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            activeIcon: const Icon(Icons.shopping_bag_rounded),
            label: context.tr('expenses'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_outlined),
            activeIcon: const Icon(Icons.restaurant_rounded),
            label: context.tr('meals'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view_rounded),
            label: context.tr('more'),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuScreen extends StatelessWidget {
  const _MoreMenuScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('more')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.people_outline_rounded,
            color: AppColors.primary,
            title: context.tr('mess_members'),
            subtitle: 'Manage roommates, roles, and invite codes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MembersScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.handshake_outlined,
            color: const Color(0xFFD97706),
            title: context.tr('monthly_settlement'),
            subtitle: 'Who owes whom, pay balances, and cycle close',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettlementScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart_rounded,
            color: AppColors.secondary,
            title: context.tr('reports'),
            subtitle: 'Category distribution and monthly analytics',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            color: AppColors.neutral,
            title: context.tr('settings'),
            subtitle: 'Language, profile, legal, and preferences',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }
}
