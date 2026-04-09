import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/admin/admin_add_inventory.dart';
import 'package:recycle_go/view/admin/admin_inventory.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/admin_update_inventory.dart';
import 'package:recycle_go/view/autho/register_screen.dart';
import 'package:recycle_go/view/profile/profile_screen.dart';
import 'package:recycle_go/view/recycle/map_screen.dart';
import 'package:recycle_go/view/recycle/station_detail_screen.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';
import 'package:recycle_go/view/admin/admin_station_edit.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MainApp(),
    ),
  );
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      initialRoute: Routes.adminStationRegistry,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.userHomePage: (context) => const HomePage(),
        Routes.userProfile: (context) => const ProfileScreen(),
        Routes.adminHome: (context) => const AdminHome(),
        Routes.adminPurchaseDetail: (context) =>
            const AdminPurchaseDetail(purchase: {}, items: []),
        Routes.adminPurchaseUpdate: (context) =>
            const AdminPurchaseUpdate(purchase: {}, items: []),
        Routes.adminInventory: (context) => const AdminInventory(),
        Routes.adminViewInventory: (context) => const AdminViewInventory(),
        Routes.adminAddInventory: (context) => const AdminAddInventory(),
        Routes.adminUpdateInventory: (context) =>
            const AdminUpdateInventory(item: {}),
        Routes.map: (context) => const MapScreen(),
        Routes.adminStationRegistry: (context) => const StationRegistryScreen(),
        Routes.adminVoucherManagement: (context) =>
            const AdminVoucherManagement(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: Text(user?.userName ?? 'User')),
      body: Center(
        child: Text(
          l10n?.hello_world ?? 'Hello World!',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
