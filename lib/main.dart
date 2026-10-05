import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_theme.dart';
import 'core/localization/app_locale.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/bill_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/meal_repository.dart';
import 'data/repositories/mess_repository.dart';
import 'data/repositories/settlement_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/mess_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase gracefully (supports cloud as well as offline/sandbox fallback)
  await SupabaseConfig.initialize();

  final prefs = await SharedPreferences.getInstance();

  final authRepo = AuthRepository(prefs);
  final messRepo = MessRepository(prefs);
  final billRepo = BillRepository(prefs);
  final expenseRepo = ExpenseRepository(prefs);
  final mealRepo = MealRepository(prefs);
  final settlementRepo = SettlementRepository(prefs);

  await authRepo.initSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(
          create: (context) {
            final provider = MessProvider(
              messRepo: messRepo,
              billRepo: billRepo,
              expenseRepo: expenseRepo,
              mealRepo: mealRepo,
              settlementRepo: settlementRepo,
            );
            final user = authRepo.currentUser;
            if (user != null) {
              provider.loadMessData(user.id);
            }
            return provider;
          },
        ),
      ],
      child: const MessHubApp(),
    ),
  );
}

class MessHubApp extends StatelessWidget {
  const MessHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'MessHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: localeProvider.locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authProvider.isAuthenticated
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
