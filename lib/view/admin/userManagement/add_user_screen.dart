import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/user_management_ctrl.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/services/email_service.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = UserManagementCtrl();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isUsernameValid = true;
  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  bool _isLoading = false;
  String _selectedCountryCode = '+60';
  final List<String> _countryCodes = ['+60', '+65', '+1', '+44', '+86', '+91'];

  void _validateFields() {
    setState(() {
      _isUsernameValid = Validators.isValidName(_usernameController.text);
      _isEmailValid = Validators.isValidEmail(_emailController.text);
      _isPhoneValid = Validators.isValidPhoneNumber(_phoneController.text, _selectedCountryCode);
    });
  }

  String _invalidPhoneMessage(String value, String countryCode) {
    if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Numbers only allowed';
    }
    switch (countryCode) {
      case '+60': return 'Enter a valid Malaysia phone number (9-10 digits)';
      case '+65': return 'Enter a valid Singapore phone number (8 digits)';
      case '+1':  return 'Enter a valid American/Canadian phone number (10 digits)';
      case '+44': return 'Enter a valid UK phone number (10 digits)';
      case '+86': return 'Enter a valid China phone number (11 digits)';
      case '+91': return 'Enter a valid India phone number (10 digits)';
      default: return 'Invalid phone number';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Add New User", style: TextDesign.appBarTitle()),
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
                  Text('User Details', style: TextDesign.headingTwo()),
                  const SizedBox(height: 8),
                  Text('A setup link will be sent to the user email to set their password.', style: TextDesign.smallText()),
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

                  AuthLabel(text: 'Phone Number (Optional)', isValid: _isPhoneValid),
                  AuthTextField(
                    controller: _phoneController,
                    hintText: '123456789',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _validateFields(),
                    prefixIcon: Container(
                      width: 80,
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              items: _countryCodes.map((String code) {
                                return DropdownMenuItem<String>(
                                  value: code,
                                  child: Text(code, style: TextDesign.normalText(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                  _validateFields();
                                });
                              },
                            ),
                          ),
                          Container(width: 1, height: 20, color: theme.border, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        ],
                      ),
                    ),
                    borderColor: _phoneController.text.isNotEmpty && !_isPhoneValid ? theme.error : null,
                    errorText: _phoneController.text.isNotEmpty && !_isPhoneValid ? _invalidPhoneMessage(_phoneController.text, _selectedCountryCode) : null,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isUsernameValid || !_isEmailValid || !_isPhoneValid) ? null : _submit,
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
    if (!_isUsernameValid || !_isEmailValid || !_isPhoneValid) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      // Check if email exists in either table (Admins or Users)
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

      final newUser = Users(
        userName: _usernameController.text.trim(),
        email: email,
        accountStatus: 'active',
        countryCallingCode: _selectedCountryCode,
        phone: _phoneController.text.trim(),
        totalPoints: 0,
        hashedPassword: 'TEMPORARY_PLACEHOLDER',
      );
      
      final usersModel = UsersModel();
      final createdUser = await usersModel.createUser(newUser);

      final emailService = EmailService();
      bool sent = await emailService.sendAdminResetLink(
        createdUser!.email,
        createdUser.userId!,
        createdUser.userName,
        isInvite: true,
        accountType: 'user',
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
            const SnackBar(content: Text('User created, but failed to send email link.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $e')),
        );
      }
    }
  }
}
