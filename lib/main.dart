import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/admin/admin_add_inventory.dart';
import 'package:recycle_go/view/admin/admin_inventory.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/admin_update_inventory.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use the auto-generated delegates and locales
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Default locale
      locale: const Locale('en'),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.userHomePage: (context) => const HomePage(),
        Routes.adminHome: (context) => const AdminHome(),
        Routes.adminPurchaseDetail: (context) => const AdminPurchaseDetail(purchase: {},items: []),
        Routes.adminPurchaseUpdate: (context) => const AdminPurchaseUpdate(purchase: {},items: [],),
        Routes.adminInventory: (context) => const AdminInventory(),
        Routes.adminViewInventory: (context) => const AdminViewInventory(),
        Routes.adminAddInventory: (context) => const AdminAddInventory(),
        Routes.adminUpdateInventory: (context) => const AdminUpdateInventory(item: {},),
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

