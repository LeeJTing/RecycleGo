import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/services/supabase_service.dart';

Future<void> main() async {
  final supabase = SupabaseService();
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Use the auto-generated delegates and locales
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Default locale
      locale: Locale('en'),
      home: HomePage(),
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
