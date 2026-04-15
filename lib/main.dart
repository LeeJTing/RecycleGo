import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/admin/admin_add_inventory.dart';
import 'package:recycle_go/view/admin/admin_inventory.dart';
import 'package:recycle_go/view/autho/forgot_password_screen.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/admin_update_inventory.dart';
import 'package:recycle_go/view/autho/register_screen.dart';
import 'package:recycle_go/view/user/homePage/home_screen.dart';
import 'package:recycle_go/view/user/profile/edit_profile_screen.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: Routes.login,
      onGenerateRoute: (settings) {
        if (settings.name == Routes.editProfile) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditProfileScreen(user: args['user']),
          );
        }
        return null;
      },
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
        Routes.userHomePage: (context) => const UserHomeScreen(initialIndex: 0),
        Routes.userProfile: (context) => const UserHomeScreen(initialIndex: 4),
        Routes.adminHome: (context) => const AdminHome(),
        Routes.adminPurchaseDetail: (context) => const AdminPurchaseDetail(purchase: {}, items: []),
        Routes.adminPurchaseUpdate: (context) => const AdminPurchaseUpdate(purchase: {}, items: []),
        Routes.adminInventory: (context) => const AdminInventory(),
        Routes.adminViewInventory: (context) => const AdminViewInventory(),
        Routes.adminAddInventory: (context) => const AdminAddInventory(),
        Routes.adminUpdateInventory: (context) =>
        AdminUpdateInventory(item: RecycleInventory(inventoryId: '', inventoryName: '', pricePerKg: 0.0)),
        Routes.map: (context) => const UserHomeScreen(initialIndex: 2),
        Routes.qrScan: (context) => const UserHomeScreen(initialIndex: 1),
        Routes.adminStationRegistry: (context) => const StationRegistryScreen(),
        Routes.adminVoucherManagement: (context) => const AdminVoucherManagement(),
      },
    );
  }
}
