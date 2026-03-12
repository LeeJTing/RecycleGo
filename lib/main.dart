import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recycle_go/bottom_nav_bar.dart';
import 'package:recycle_go/home_screen.dart';
import 'package:recycle_go/l10n/app_localizations.dart';
import 'package:recycle_go/verify_recycle_item.dart';

void main() {
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
    Center(child: VerifyRecycleItem()),
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
/*        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,*/
      ],
      supportedLocales: const [
        Locale('en'), // English
      ],
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

