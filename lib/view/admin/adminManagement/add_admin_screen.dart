import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/admin_management_ctrl.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = AdminManagementCtrl();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'normal';

  bool _isUsernameValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isLoading = false;

  void _validateFields() {
    setState(() {
      _isUsernameValid = Validators.isValidName(_usernameController.text);
      _isEmailValid = Validators.isValidEmail(_emailController.text);
      _isPasswordValid = Validators.isPasswordSecure(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add New Admin", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Details', style: TextDesign.headingTwo()),
              const SizedBox(height: 8),
              Text('Create a new administrative account.', style: TextDesign.smallText()),
              const SizedBox(height: 32),

              AuthLabel(text: 'Username', isValid: _isUsernameValid),
              AuthTextField(
                controller: _usernameController,
                onChanged: (_) => _validateFields(),
                hintText: 'Enter username',
                prefixIcon: Icon(Icons.person_outline, color: theme.onHint, size: 20),
                borderColor: _usernameController.text.isNotEmpty && !_isUsernameValid ? theme.error.withOpacity(0.3) : null,
              ),
              const SizedBox(height: 20),

              AuthLabel(text: 'Email Address', isValid: _isEmailValid),
              AuthTextField(
                controller: _emailController,
                onChanged: (_) => _validateFields(),
                hintText: 'Enter email',
                prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                borderColor: _emailController.text.isNotEmpty && !_isEmailValid ? theme.error.withOpacity(0.3) : null,
              ),
              const SizedBox(height: 20),

              AuthLabel(text: 'Password', isValid: _isPasswordValid),
              AuthTextField(
                controller: _passwordController,
                onChanged: (_) => _validateFields(),
                hintText: 'Enter password',
                obscureText: true,
                prefixIcon: Icon(Icons.lock_outline, color: theme.onHint, size: 20),
                borderColor: _passwordController.text.isNotEmpty && !_isPasswordValid ? theme.error.withOpacity(0.3) : null,
                errorText: _passwordController.text.isNotEmpty && !_isPasswordValid ? 'Password must be 7-12 chars with upper, lower, number, and special char.' : null,
              ),
              const SizedBox(height: 20),

              const AuthLabel(text: 'Admin Role'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                    items: <String>['normal', 'super admin']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase(), style: TextDesign.normalText()),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    disabledBackgroundColor: theme.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Create Admin', style: TextDesign.buttonText()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _validateFields();
    if (!_isUsernameValid || !_isEmailValid || !_isPasswordValid) return;

    setState(() => _isLoading = true);
    try {
      await _ctrl.addAdmin(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create admin: $e')),
        );
      }
    }
  }
}
