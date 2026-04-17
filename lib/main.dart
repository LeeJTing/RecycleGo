import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
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
import 'package:recycle_go/view/user/user_shell.dart';
import 'package:recycle_go/view/user/purchase/user_purchase.dart';
import 'package:recycle_go/view/user/purchase/purchase_history.dart';
import 'package:recycle_go/view/user/purchase/purchase_detail.dart';
import 'package:recycle_go/view/user/purchase/payment_success.dart';
import 'package:recycle_go/view/user/purchase/payment_verification.dart';
import 'package:recycle_go/view/recycle/qr_scan_screen.dart';
import 'package:recycle_go/view/admin/adminManagement/admin_management_screen.dart';

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
      initialRoute: Routes.map,
      onGenerateRoute: (settings) {
        if (settings.name == Routes.editProfile) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditProfileScreen(user: args['user']),
          );
        }
        if (settings.name == Routes.userPurchaseDetail) {
          final args = settings.arguments as Map<String, dynamic>;
          final purchase = args['purchase'] as RecyclePurchases;
          return MaterialPageRoute(
            builder: (context) => PurchaseDetailScreen(purchase: purchase),
          );
        }
        if (settings.name == Routes.paymentSuccess) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              itemName: args['itemName'] as String,
              quantity: args['quantity'] as double,
              totalPrice: args['totalPrice'] as double,
              purchaseId: args['purchaseId'] as String,
              bankAccount: args['bankAccount'] as String?,
            ),
          );
        }
        if (settings.name == Routes.paymentVerification) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PaymentVerificationScreen(
              sessionId: args['sessionId'] as String,
              purchaseId: args['purchaseId'] as String,
              itemName: args['itemName'] as String,
              quantity: args['quantity'] as double,
              totalPrice: args['totalPrice'] as double,
              inventoryId: args['inventoryId'] as String,
            ),
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
        Routes.adminPurchaseDetail: (context) =>
            const AdminPurchaseDetail(purchase: {}, items: []),
        Routes.adminPurchaseUpdate: (context) =>
            const AdminPurchaseUpdate(purchase: {}, items: []),
        Routes.adminInventory: (context) => const AdminInventory(),
        Routes.adminViewInventory: (context) => AdminViewInventory(
          item: RecycleInventory(
            inventoryId: '',
            inventoryName: '',
            pricePerKg: 0.0,
            totalWeightAvailable: 0.0,
            status: '',
          ),
        ),
        Routes.adminAddInventory: (context) => const AdminAddInventory(),

        Routes.adminUpdateInventory: (context) => AdminUpdateInventory(
          item: RecycleInventory(
            inventoryId: '',
            inventoryName: '',
            pricePerKg: 0.0,
            totalWeightAvailable: 0.0,
            status: '',
          ),
        ),
        Routes.map: (context) => const UserHomeScreen(initialIndex: 2),
        Routes.qrScan: (context) => const UserHomeScreen(initialIndex: 1),

        Routes.adminStationRegistry: (context) => const StationRegistryScreen(),
        Routes.adminVoucherManagement: (context) =>
            const AdminVoucherManagement(),
        Routes.userPurchase: (context) => const UserPurchaseScreen(),
        Routes.userPurchaseHistory: (context) => const PurchaseHistoryScreen(),
        
        // Management Routes
        Routes.adminUserManagement: (context) => Scaffold(appBar: AppBar(title: const Text("User management")), body: const Center(child: Text("User Management Screen"))),
        Routes.adminManagement: (context) => const AdminManagementScreen(),
        Routes.adminAppealReview: (context) => Scaffold(appBar: AppBar(title: const Text("Appeal Review")), body: const Center(child: Text("Appeal Review Screen"))),
      },
    );
  }
}
