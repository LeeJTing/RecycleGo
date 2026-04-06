import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/app/routes.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/provider/UserProvider.dart';
import 'package:recycle_go/provider/AdminProvider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _selectFirstUser() async {
    setState(() => _isLoading = true);
    try {
      final userModel = UsersModel();
      final user = await userModel.getFirstUser();
      if (user != null && mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected user: ${user.userName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final user = userProvider.user;
    final admin = adminProvider.admin;

    final theme = AppThemes.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextDesign.appBarTitle()),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user != null) ...[
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 20),
                    Text('User Mode', style: TextDesign.headingOne(color: theme.primary)),
                    const SizedBox(height: 10),
                    Text('Name: ${user.userName}', style: TextDesign.normalText()),
                    Text('Email: ${user.email}', style: TextDesign.normalText()),
                    Text('Points: ${user.totalPoints}', style: TextDesign.priceText()),
                    Text('Status: ${user.accountStatus}', style: TextDesign.smallText()),
                  ] else if (admin != null) ...[
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text('Admin Mode', style: TextDesign.headingOne(color: Colors.redAccent)),
                    const SizedBox(height: 10),
                    Text('Username: ${admin.username}', style: TextDesign.normalText()),
                    Text('Email: ${admin.email}', style: TextDesign.normalText()),
                    Text('Role: ${admin.role}', style: TextDesign.largeText()),
                    Text('Status: ${admin.adminStatus}', style: TextDesign.smallText()),
                  ] else ...[
                    const Icon(Icons.error_outline, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text('No user or admin data found.', style: TextDesign.normalText()),
                  ],
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _selectFirstUser,
                    child: const Text('Fetch & Select First User (Testing)'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
