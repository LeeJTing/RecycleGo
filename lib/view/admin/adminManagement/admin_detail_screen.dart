import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/controller/admin/admin_management_ctrl.dart';
import 'package:recycle_go/provider/AdminProvider.dart';
import 'package:recycle_go/services/email_service.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class AdminDetailScreen extends StatefulWidget {
  final Admins admin;

  const AdminDetailScreen({super.key, required this.admin});

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  late TextEditingController _usernameController;
  late String _selectedRole;
  late String _selectedStatus;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUsernameValid = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.admin.username);
    _selectedRole = widget.admin.role;
    _selectedStatus = widget.admin.adminStatus;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      _isUsernameValid = Validators.isValidName(_usernameController.text);
    });
  }

  Future<void> _updateAdmin() async {
    _validateFields();
    if (!_isUsernameValid) return;

    setState(() => _isLoading = true);
    try {
      final ctrl = AdminManagementCtrl();

      await ctrl.updateName(
        widget.admin.adminId!,
        _usernameController.text.trim(),
      );
      await ctrl.updateAdminRole(widget.admin.adminId!, _selectedRole);
      await ctrl.updateAdminStatus(widget.admin.adminId!, _selectedStatus);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin details updated successfully!')),
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
        widget.admin.email,
        widget.admin.adminId!,
        widget.admin.username,
        isInvite: false,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (sent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reset password link sent to admin email.'),
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
        title: Text("Admin Details", style: TextDesign.appBarTitle()),
        backgroundColor: theme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, _) {
              final isSelf =
                  adminProvider.admin?.adminId == widget.admin.adminId;
              if (isSelf) return const SizedBox.shrink();

              return IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  color: theme.primary,
                ),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              );
            },
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
                  backgroundColor: theme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, size: 50, color: theme.primary),
                ),
                const SizedBox(height: 16),
                if (!_isEditing) ...[
                  Text(widget.admin.username, style: TextDesign.headingTwo()),
                  Text(
                    widget.admin.email,
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
                        ? theme.error.withOpacity(0.3)
                        : null,
                  ),
                ],
                const SizedBox(height: 32),
                _buildDetailTile(
                  icon: Icons.badge_outlined,
                  label: "Admin ID",
                  value: widget.admin.adminId ?? "N/A",
                  theme: theme,
                ),
                if (!_isEditing) ...[
                  _buildDetailTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: "Role",
                    value: _selectedRole.toUpperCase(),
                    theme: theme,
                  ),
                  _buildDetailTile(
                    icon: Icons.info_outline,
                    label: "Status",
                    value: _selectedStatus.toUpperCase(),
                    theme: theme,
                    valueColor: _selectedStatus == 'active'
                        ? theme.success
                        : theme.error,
                  ),
                ] else ...[
                  _buildEditDropdown(
                    icon: Icons.admin_panel_settings_outlined,
                    label: "Role",
                    value: _selectedRole,
                    items: ['normal', 'super admin'],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                    theme: theme,
                  ),
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
                  label: "Created At",
                  value: widget.admin.createdAt != null
                      ? formatter.format(widget.admin.createdAt!)
                      : "N/A",
                  theme: theme,
                ),

                const SizedBox(height: 24),
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<AdminProvider>(
                      builder: (context, adminProvider, _) {
                        final isSelf =
                            adminProvider.admin?.adminId ==
                            widget.admin.adminId;
                        if (isSelf) return const SizedBox.shrink();
                        return OutlinedButton.icon(
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
                        );
                      },
                    ),
                  ),

                if (_isEditing) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateAdmin,
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
          Icon(icon, color: theme.primary),
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
          Icon(icon, color: theme.primary),
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
