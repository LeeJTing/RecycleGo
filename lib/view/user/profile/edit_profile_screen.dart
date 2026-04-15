import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/profile/profile_ctrl.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final Users user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final ProfileCtrl _ctrl = ProfileCtrl();

  bool _isNameValid = true;
  bool _isPhoneValid = true;
  String _selectedCountryCode = '+60';
  final List<String> _countryCodes = ['+60', '+65', '+1', '+44', '+86', '+91'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.userName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedCountryCode = widget.user.countryCallingCode ?? '+60';
    _validateFields();
  }

  void _validateFields() {
    setState(() {
      _isNameValid = Validators.isValidName(_nameController.text);
      _isPhoneValid = Validators.isValidPhoneNumber(_phoneController.text, _selectedCountryCode);
    });
  }

  String _invalidPhoneMessage(String countryCode) {
    switch (countryCode) {
      case '+60': return 'Please enter a valid Malaysia phone number (9 or 10 digits)';
      case '+65': return 'Please enter a valid Singapore phone number (8 digits)';
      case '+1':  return 'Please enter a valid American/Canadian phone number (10 digits)';
      case '+44': return 'Please enter a valid UK phone number (10 digits)';
      case '+86': return 'Please enter a valid China phone number (11 digits)';
      case '+91': return 'Please enter a valid India phone number (10 digits)';
      default: return 'Invalid phone number';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextDesign.appBarTitle()),
        backgroundColor: Colors.transparent,
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
              Text('Profile Details', style: TextDesign.headingTwo()),
              const SizedBox(height: 8),
              Text('Update your information below.', style: TextDesign.smallText()),
              const SizedBox(height: 32),
              
              AuthLabel(text: 'Full Name', isValid: _isNameValid),
              AuthTextField(
                controller: _nameController,
                onChanged: (_) => _validateFields(),
                hintText: 'Adam Lim',
                prefixIcon: Icon(Icons.person_outline, color: theme.onHint, size: 20),
                borderColor: _nameController.text.isNotEmpty && !_isNameValid ? theme.error.withOpacity(0.3) : null,
                errorText: _nameController.text.isNotEmpty && !_isNameValid ? 'Only letters and spaces allowed' : null,
              ),
              const SizedBox(height: 20),
              
              AuthLabel(text: 'Phone Number', isValid: _isPhoneValid),
              AuthTextField(
                controller: _phoneController,
                hintText: '123456789',
                keyboardType: TextInputType.phone,
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
                errorText: _phoneController.text.isNotEmpty && !_isPhoneValid ? _invalidPhoneMessage(_selectedCountryCode) : null,
              ),
              const SizedBox(height: 20),
              
              const AuthLabel(text: 'Email Address (Read Only)'),
              AuthTextField(
                controller: TextEditingController(text: widget.user.email),
                readOnly: true,
                hintText: '',
                prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                filled: true,
                fillColor: theme.surfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isNameValid && _isPhoneValid) ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    disabledBackgroundColor: theme.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Save Changes', style: TextDesign.buttonText()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    final updatedUser = widget.user.copyWith(
      userName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      countryCallingCode: _selectedCountryCode,
    );
    await _ctrl.updateProfile(context, updatedUser);
    if (mounted) Navigator.pop(context);
  }
}
