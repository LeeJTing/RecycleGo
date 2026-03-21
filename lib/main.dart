import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/autho/login_screen.dart';


import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    Center(child: HomeScreen()),
    Center(child: Text('Scan Screen')),
    // Center(child: VerifyRecycleItem()),
    Center(child: Text('Rewards Screen')),
    Center(child: Text('Profile Screen')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use the auto-generated delegates and locales
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Default locale
      locale: const Locale('en'),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.userHomePage: (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Now context is BELOW MaterialApp, so AppLocalizations.of(context) will work
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: Center(
        child: Text(
          l10n?.hello_world ?? 'Hello World!',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

