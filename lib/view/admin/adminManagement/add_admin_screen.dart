import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/admin_management_ctrl.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/services/email_service.dart';
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
  String _selectedRole = 'normal';

  bool _isUsernameValid = true;
  bool _isEmailValid = true;
  bool _isLoading = false;

  void _validateFields() {
    setState(() {
      _isUsernameValid = Validators.isValidName(_usernameController.text);
      _isEmailValid = Validators.isValidEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Details', style: TextDesign.headingTwo()),
                  const SizedBox(height: 8),
                  Text('A setup link will be sent to the admin email to set their password.', style: TextDesign.smallText()),
                  const SizedBox(height: 32),

                  AuthLabel(text: 'Username', isValid: _isUsernameValid),
                  AuthTextField(
                    controller: _usernameController,
                    onChanged: (_) => _validateFields(),
                    hintText: 'Enter username',
                    prefixIcon: Icon(Icons.person_outline, color: theme.onHint, size: 20),
                    borderColor: _usernameController.text.isNotEmpty && !_isUsernameValid ? theme.error : null,
                    errorText: _usernameController.text.isNotEmpty && !_isUsernameValid ? 'Only letters and spaces allowed' : null,
                  ),
                  const SizedBox(height: 20),

                  AuthLabel(text: 'Email Address', isValid: _isEmailValid),
                  AuthTextField(
                    controller: _emailController,
                    onChanged: (_) => _validateFields(),
                    hintText: 'Enter email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                    borderColor: _emailController.text.isNotEmpty && !_isEmailValid ? theme.error : null,
                    errorText: _emailController.text.isNotEmpty && !_isEmailValid ? 'Please enter a valid email address' : null,
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
                        dropdownColor: theme.surface,
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
                      onPressed: (_isLoading || !_isUsernameValid || !_isEmailValid) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        disabledBackgroundColor: theme.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Send Invite Link', style: TextDesign.buttonText(color: theme.onPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    _validateFields();
    if (!_isUsernameValid || !_isEmailValid) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      // Dual check email uniqueness across BOTH tables
      final adminExists = await AdminsModel().emailIsExist(email);
      final userExists = await UsersModel().emailIsExist(email);

      if (adminExists || userExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This email is already registered.')),
          );
        }
        return;
      }

      // 1. Create Admin with placeholder password
      final tempAdmin = Admins(
        username: _usernameController.text.trim(),
        email: email,
        adminStatus: 'active',
        role: _selectedRole,
        hashedPassword: 'TEMPORARY_PLACEHOLDER', // Will be reset via link
      );
      
      final adminModel = AdminsModel();
      final createdAdmin = await adminModel.insertAdmin(tempAdmin);

      // 2. Send setup email
      final emailService = EmailService();
      bool sent = await emailService.sendAdminResetLink(
        createdAdmin.email,
        createdAdmin.adminId!,
        createdAdmin.username,
        isInvite: true,
        accountType: 'admin',
      );

      if (mounted) {
        if (sent) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation link sent successfully!')),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin created, but failed to send email link.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add admin: $e')),
        );
      }
    }
  }
}
