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
import 'package:recycle_go/view/admin/admin_recycle_category.dart';
import 'package:recycle_go/view/admin/category/admin_add_category.dart';
import 'package:recycle_go/view/admin/category/admin_update_category.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/admin_update_inventory.dart';
import 'package:recycle_go/view/autho/register_screen.dart';
//import 'package:recycle_go/view/profile/profile_screen.dart';
import 'package:recycle_go/view/recycle/map_screen.dart';
import 'package:recycle_go/view/recycle/station_detail_screen.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';
import 'package:recycle_go/view/admin/admin_station_edit.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/models/RecycleInventory.dart';

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
      initialRoute: Routes.adminHome,
      // Use onGenerateRoute for full control and type safety
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
        // Auth routes
          case Routes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case Routes.register:
            return MaterialPageRoute(builder: (_) => const RegisterScreen());

        // User routes
          case Routes.userHomePage:
            return MaterialPageRoute(builder: (_) => const HomePage());
          case Routes.userProfile:
            //return MaterialPageRoute(builder: (_) => const ProfileScreen());

        // Admin routes
          case Routes.adminHome:
            return MaterialPageRoute(builder: (_) => const AdminHome());
          case Routes.adminNotification:
          // TODO: Create NotificationScreen
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Notifications Screen')),
              ),
            );

          case Routes.adminPurchaseDetail:
            final args = settings.arguments as AdminPurchaseDetail?;
            if (args == null) {
              return _errorRoute('Missing purchase details');
            }
            return MaterialPageRoute(
              builder: (_) => AdminPurchaseDetail(
                purchase: args.purchase,
                items: args.items,
              ),
            );

          case Routes.adminPurchaseUpdate:
            final args = settings.arguments as AdminPurchaseUpdate?;
            if (args == null) {
              return _errorRoute('Missing purchase update data');
            }
            return MaterialPageRoute(
              builder: (_) => AdminPurchaseUpdate(
                purchase: args.purchase,
                items: args.items,
              ),
            );

          case Routes.adminInventory:
            return MaterialPageRoute(builder: (_) => const AdminInventory());

          case Routes.adminViewInventory:
          // Just cast it directly to RecycleInventory!
            final item = settings.arguments as RecycleInventory?;
            if (item == null) {
              return _errorRoute('Missing inventory item');
            }
            return MaterialPageRoute(
              builder: (_) => AdminViewInventory(item: item),
            );

          case Routes.adminAddInventory:
            return MaterialPageRoute(builder: (_) => const AdminAddInventory());

          case Routes.adminUpdateInventory:
          // Just cast it directly to RecycleInventory!
            final item = settings.arguments as RecycleInventory?;
            if (item == null) {
              return _errorRoute('Missing inventory item for update');
            }
            return MaterialPageRoute(
              builder: (_) => AdminUpdateInventory(item: item),
            );

          case Routes.map:
            return MaterialPageRoute(builder: (_) => const MapScreen());

          case Routes.adminAddCategory:
            return MaterialPageRoute(builder: (_) => const AdminAddCategory());

          case Routes.adminUpdateCategory:
            return MaterialPageRoute(builder: (_) => const AdminUpdateCategory());

          case Routes.adminStationRegistry:
            return MaterialPageRoute(builder: (_) => const StationRegistryScreen());

          case Routes.adminVoucherManagement:
            return MaterialPageRoute(builder: (_) => const AdminVoucherManagement());

        // Add other routes as needed (stationDetail, qrScan, etc.)
          default:
            return _errorRoute('Route not found: ${settings.name}');
        }
      },
    );
  }

  // Helper to show a graceful error screen
  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

// HomePage widget (keep as is or move to its own file)
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