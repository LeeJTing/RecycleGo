import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/l10n/app_localization.dart';
import 'package:recycle_go/models/RecycleInventory.dart';
import 'package:recycle_go/models/RecyclePurchases.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/provider/CategoryProvider.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/services/supabase_service.dart';
import 'package:recycle_go/view/admin/inventory/admin_add_inventory.dart';
import 'package:recycle_go/view/admin/admin_full_request_review.dart';
import 'package:recycle_go/view/admin/inventory/admin_inventory.dart';
import 'package:recycle_go/view/admin/purchase/admin_view_purchase.dart';
import 'package:recycle_go/view/admin/category/admin_add_category.dart';
import 'package:recycle_go/view/admin/category/admin_update_category.dart';
import 'package:recycle_go/view/admin/userManagement/user_management_screen.dart';
import 'package:recycle_go/view/autho/forgot_password_screen.dart';
import 'package:recycle_go/view/autho/login_screen.dart';
import 'package:recycle_go/view/admin/admin_home.dart';
import 'package:recycle_go/view/admin/purchase/admin_purchase_detail.dart';
import 'package:recycle_go/view/admin/purchase/admin_purchase_update.dart';
import 'package:recycle_go/view/admin/inventory/admin_view_inventory.dart';
import 'package:recycle_go/view/admin/inventory/admin_update_inventory.dart';
import 'package:recycle_go/view/autho/register_screen.dart';
import 'package:recycle_go/view/autho/reset_password_screen.dart';
import 'package:recycle_go/view/user/AI-verify-recycle/verify_recycle_item.dart';
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
import 'package:recycle_go/view/admin/admin_notification_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:recycle_go/view/admin/profile/admin_profile_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:recycle_go/services/notification_services.dart';


Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  if (notification != null) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'station_channel',
          'Station Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseService.initialize();
  await initNotifications();
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'station_channel',
    'Station Notifications',
    description: 'Notify when station is created',
    importance: Importance.max,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
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
  bool _isNavigating = false;
  final ValueNotifier<bool> _isAppReady = ValueNotifier<bool>(false);

  void _initFCM() async {
    await FirebaseMessaging.instance.subscribeToTopic("stations");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        notificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'station_channel',
              'Station Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigatorKey.currentState?.pushNamed(Routes.map);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _navigatorKey.currentState?.pushNamed(Routes.map);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFCM();
    
    // Step 1: Initialize the base app and wait for stability
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _isAppReady.value = true;
        _initDeepLinks();
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _isAppReady.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links while app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('DEBUG: Received Link from Stream: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('AppLinks Error: $err');
      },
    );

    // Handle links that opened the app (Cold Start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DEBUG: Cold Start Link: $initialUri');
        // We wait for the app to be ready before processing the cold start link
        if (_isAppReady.value) {
          _handleDeepLink(initialUri);
        } else {
          late VoidCallback listener;

          listener = () {
            if (_isAppReady.value) {
              _handleDeepLink(initialUri);
              _isAppReady.removeListener(listener);
            }
          };

          _isAppReady.addListener(listener);
        }
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (_isNavigating) return;

    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final path = uri.path.toLowerCase();

    // Supports recyclego://reset-password and https://recyclego/reset-password
    if ((scheme == 'recyclego' && host == 'reset-password') ||
        (scheme == 'https' && path == '/reset-password')) {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty && !_handledTokens.contains(token)) {
        _handledTokens.add(token);
        _safeNavigate(Routes.resetPassword, {'token': token});
      }
    }
  }

  void _safeNavigate(String routeName, Map<String, dynamic> args) {
    if (!mounted) return;
    
    _isNavigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamed(routeName, arguments: args);
      _isNavigating = false;
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
      initialRoute: Routes.login,
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('recyclego://payment/') == true) {
          if (settings.name == 'recyclego://payment/success') {
            return MaterialPageRoute(builder: (context) => const UserHomeScreen(initialIndex: 0));
          } else if (settings.name == 'recyclego://payment/cancelled') {
            return MaterialPageRoute(builder: (context) => const UserPurchaseScreen());
          }
        }
        if (settings.name == Routes.resetPassword) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (context) => ResetPasswordScreen(token: args['token']));
        }
        if (settings.name == Routes.editProfile) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (context) => EditProfileScreen(user: args['user']));
        }
        if (settings.name == Routes.userPurchaseDetail) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (context) => PurchaseDetailScreen(purchase: args['purchase']));
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
        Routes.adminPurchaseView: (context) => const AdminViewPurchase(),
        Routes.adminPurchaseDetail: (context) {
          final purchase = ModalRoute.of(context)!.settings.arguments as RecyclePurchases;
          return AdminPurchaseDetail(purchase: purchase, items: const []);
        },
        Routes.adminPurchaseUpdate: (context) {
          final purchase = ModalRoute.of(context)!.settings.arguments as RecyclePurchases;
          return AdminPurchaseUpdate(purchase: purchase, items: const []);
        },
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
        Routes.adminVoucherManagement: (context) => const AdminVoucherManagement(),
        Routes.userPurchase: (context) => const UserPurchaseScreen(),
        Routes.userPurchaseHistory: (context) => const PurchaseHistoryScreen(),
        Routes.adminUserManagement: (context) => const UserManagementScreen(),
        Routes.adminManagement: (context) => const AdminManagementScreen(),
        Routes.adminAppealReview: (context) => const AppealReviewScreen(),
        Routes.userNotification: (context) => const NotificationListScreen(),
        Routes.adminNotification: (context) => const AdminNotificationScreen(),
        Routes.scanRecycleItem: (context) => const VerifyRecycleItem(),
        Routes.adminFullRequestReview: (context) => const AdminSubmissionFullReview(),
        Routes.adminProfile: (context) => const AdminProfileScreen(),
        Routes.adminAddCategory: (context)=> const AdminAddCategory(),
        Routes.adminUpdateCategory: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as AdminUpdateCategory;
          return AdminUpdateCategory(category: args.category);
        },
      },
    );
  }
}
