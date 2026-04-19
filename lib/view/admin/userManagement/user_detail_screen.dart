import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/user_management_ctrl.dart';
import 'package:recycle_go/models/Users.dart';
import 'package:recycle_go/services/email_service.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class UserDetailScreen extends StatefulWidget {
  final Users user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late String _selectedStatus;
  late String _selectedCountryCode;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUsernameValid = true;
  bool _isPhoneValid = true;

  final List<String> _countryCodes = ['+60', '+65', '+1', '+44', '+86', '+91'];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.userName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedStatus = widget.user.accountStatus;
    _selectedCountryCode = widget.user.countryCallingCode ?? '+60';
    _validateFields();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      _isUsernameValid = Validators.isValidName(_usernameController.text);
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

  Future<void> _updateUser() async {
    _validateFields();
    if (!_isUsernameValid || !_isPhoneValid) return;

    setState(() => _isLoading = true);
    try {
      final ctrl = UserManagementCtrl();
      
      final updatedUser = widget.user.copyWith(
        userName: _usernameController.text.trim(),
        countryCallingCode: _selectedCountryCode,
        phone: _phoneController.text.trim(),
        accountStatus: _selectedStatus,
      );

      await ctrl.updateUserDetails(updatedUser);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _sendResetPasswordEmail() async {
    setState(() => _isLoading = true);
    try {
      final emailService = EmailService();
      bool sent = await emailService.sendAdminResetLink(
        widget.user.email,
        widget.user.userId!,
        widget.user.userName,
        isInvite: false,
        accountType: 'user',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (sent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reset password link sent to user email.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send reset link.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("User Details", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: theme.primary,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.secondary.withValues(alpha: 0.1),
                  child: ClipOval(
                    child: Image.network(
                      widget.user.getUserProfileURL(),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 50, color: theme.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing) ...[
                  Text(widget.user.userName, style: TextDesign.headingTwo()),
                  Text(
                    widget.user.email,
                    style: TextDesign.normalText(color: theme.hint),
                  ),
                ] else ...[
                  AuthLabel(text: 'Username', isValid: _isUsernameValid),
                  AuthTextField(
                    controller: _usernameController,
                    onChanged: (_) => _validateFields(),
                    hintText: 'Enter username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.onHint,
                      size: 20,
                    ),
                    borderColor:
                        _usernameController.text.isNotEmpty && !_isUsernameValid
                        ? theme.error
                        : null,
                    errorText: _usernameController.text.isNotEmpty && !_isUsernameValid ? 'Only letters and spaces allowed' : null,
                  ),
                ],
                const SizedBox(height: 32),
                _buildDetailTile(
                  icon: Icons.badge_outlined,
                  label: "User ID",
                  value: widget.user.userId ?? "N/A",
                  theme: theme,
                ),
                _buildDetailTile(
                  icon: Icons.stars_outlined,
                  label: "Total Points",
                  value: "${widget.user.totalPoints} pts",
                  theme: theme,
                  valueColor: theme.primary,
                ),
                if (!_isEditing) ...[
                  _buildDetailTile(
                    icon: Icons.phone_outlined,
                    label: "Phone",
                    value: "${widget.user.countryCallingCode ?? ''} ${widget.user.phone ?? 'Not provided'}",
                    theme: theme,
                  ),
                  _buildDetailTile(
                    icon: Icons.info_outline,
                    label: "Account Status",
                    value: _selectedStatus.toUpperCase(),
                    theme: theme,
                    valueColor: _selectedStatus == 'active'
                        ? theme.success
                        : theme.error,
                  ),
                ] else ...[
                  AuthLabel(text: 'Phone Number (Optional)', isValid: _isPhoneValid),
                  AuthTextField(
                    controller: _phoneController,
                    hintText: '123456789',
                    keyboardType: TextInputType.number,
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
                  const SizedBox(height: 16),
                  _buildEditDropdown(
                    icon: Icons.info_outline,
                    label: "Status",
                    value: _selectedStatus,
                    items: ['active', 'inactive'],
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                    theme: theme,
                  ),
                ],
                _buildDetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: "Joined At",
                  value: widget.user.createdAt != null
                      ? formatter.format(widget.user.createdAt!)
                      : "N/A",
                  theme: theme,
                ),

                const SizedBox(height: 24),
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : _sendResetPasswordEmail,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text("Send Reset Password Link"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.primary),
                        foregroundColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                if (_isEditing) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isUsernameValid || !_isPhoneValid) ? null : _updateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Save Changes",
                        style: TextDesign.buttonText(color: theme.onPrimary),
                      ),
                    ),
                  ),
                ],
              ],
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

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required AppColors theme,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextDesign.smallText(color: theme.hint)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextDesign.normalText(
                    color: valueColor ?? theme.onSurface,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required AppColors theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextDesign.smallText(color: theme.hint)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: theme.surface,
                    style: TextDesign.normalText(
                      color: theme.onSurface,
                    ).copyWith(fontWeight: FontWeight.bold),
                    onChanged: onChanged,
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
