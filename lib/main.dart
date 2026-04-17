import 'dart:async';
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
import 'package:recycle_go/view/admin/userManagement/user_management_screen.dart';
import 'package:recycle_go/view/autho/forgot_password_screen.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/admin_update_inventory.dart';
import 'package:recycle_go/view/autho/register_screen.dart';
import 'package:recycle_go/view/autho/reset_password_screen.dart';
import 'package:recycle_go/view/user/homePage/home_screen.dart';
import 'package:recycle_go/view/user/profile/edit_profile_screen.dart';
import 'package:recycle_go/view/admin/admin_station_registry.dart';
import 'package:recycle_go/view/admin/admin_voucher_management.dart';
import 'package:recycle_go/view/user/purchase/user_purchase.dart';
import 'package:recycle_go/view/user/purchase/purchase_history.dart';
import 'package:recycle_go/view/user/purchase/purchase_detail.dart';
import 'package:recycle_go/view/user/purchase/payment_success.dart';
import 'package:recycle_go/view/user/purchase/payment_verification.dart';
import 'package:recycle_go/view/admin/adminManagement/admin_management_screen.dart';
import 'package:recycle_go/view/user/notifications/notification_list_screen.dart';
import 'package:recycle_go/view/admin/appealReview/appeal_review_screen.dart';
import 'package:app_links/app_links.dart';

import 'controller/admin/category_controller.dart';
import 'controller/admin/inventory_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CategoryController()),
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final Set<String> _handledTokens = {};

  @override
  void initState() {
    super.initState();
    // Initialize deep links after the first frame to ensure Navigator is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Handle links while the app is already open (Background/Foreground)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('AppLinks Error: $err');
    });

    // 2. Handle the link that opened the app (Cold Start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // CRITICAL: Delay navigation to ensure the initial route (Login) is completely loaded
        // This solves the 'framework.dart' assertion error.
        Future.delayed(const Duration(seconds: 10), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('DEBUG: Processing URI: $uri');
    
    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();

    // Check for host 'recyclego' and path '/reset-password'
    if ((host == 'recyclego' || scheme == 'recyclego') && uri.path.contains('reset-password')) {
      final token = uri.queryParameters['token'];
      
      if (token != null && token.isNotEmpty && !_handledTokens.contains(token)) {
        _handledTokens.add(token); // Prevent duplicate navigation for the same token
        _safeNavigate(Routes.resetPassword, {'token': token});
      }
    }
  }

  void _safeNavigate(String routeName, Map<String, dynamic> args) {
    if (!mounted) return;

    // Use addPostFrameCallback to ensure navigation doesn't happen during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState?.pushNamed(routeName, arguments: args);
      } else {
        // Final retry delay for slow devices
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.pushNamed(routeName, arguments: args);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),

      initialRoute: Routes.adminHome,
      onGenerateRoute: (settings) {
        // Handle payment deep links from Stripe
        if (settings.name?.startsWith('recyclego://payment/') == true) {
          if (settings.name == 'recyclego://payment/success') {
            // Payment succeeded - close browser and go to home
            return MaterialPageRoute(
              builder: (context) => const UserHomeScreen(initialIndex: 0),
            );
          } else if (settings.name == 'recyclego://payment/cancelled') {
            // Payment cancelled - go back to purchase screen
            return MaterialPageRoute(
              builder: (context) => const UserPurchaseScreen(),
            );
          }
        if (settings.name == Routes.resetPassword) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: args['token']),
          );
        }
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
              pickupLocationId: args['pickupLocationId'] as String?,
              pickupLocationName: args['pickupLocationName'] as String?,
              pickupAddress: args['pickupAddress'] as String?,
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
              pickupLocationId: args['pickupLocationId'] as String?,
              pickupLocationName: args['pickupLocationName'] as String?,
              pickupAddress: args['pickupAddress'] as String?,
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
        Routes.adminViewInventory: (context) {
          final item = ModalRoute.of(context)!.settings.arguments as RecycleInventory;
          return AdminViewInventory(item: item);
        },
        Routes.adminAddInventory: (context) => const AdminAddInventory(),
        Routes.adminUpdateInventory: (context) {
          final item = ModalRoute.of(context)!.settings.arguments as RecycleInventory;
          return AdminUpdateInventory(item: item);
        },
        Routes.map: (context) => const UserHomeScreen(initialIndex: 2),
        Routes.qrScan: (context) => const UserHomeScreen(initialIndex: 1),

        Routes.adminStationRegistry: (context) => const StationRegistryScreen(),
        Routes.adminVoucherManagement: (context) =>
            const AdminVoucherManagement(),
        Routes.userPurchase: (context) => const UserPurchaseScreen(),
        Routes.userPurchaseHistory: (context) => const PurchaseHistoryScreen(),

        // Management Routes
        Routes.adminUserManagement: (context) => Scaffold(
          appBar: AppBar(title: const Text("User management")),
          body: const Center(child: Text("User Management Screen")),
        ),
        Routes.adminManagement: (context) => const AdminManagementScreen(),
        Routes.adminAppealReview: (context) => Scaffold(
          appBar: AppBar(title: const Text("Appeal Review")),
          body: const Center(child: Text("Appeal Review Screen")),
        ),
        Routes.adminUserManagement: (context) => const UserManagementScreen(),
        Routes.adminManagement: (context) => const AdminManagementScreen(),
        Routes.adminAppealReview: (context) => const AppealReviewScreen(),
        Routes.userNotification: (context) => const NotificationListScreen(),
      },
    );
  }
}
