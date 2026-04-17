import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/controller/admin/admin_profile_ctrl.dart';
import 'package:recycle_go/models/Admins.dart';
import 'package:recycle_go/utils/validators.dart';
import 'package:recycle_go/utils/async_task_runner.dart';
import 'package:recycle_go/view/autho/widgets/auth_label.dart';
import 'package:recycle_go/view/autho/widgets/auth_text_field.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final Admins admin;
  const EditAdminProfileScreen({super.key, required this.admin});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final AdminProfileCtrl _ctrl = AdminProfileCtrl();

  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.username);
    _validateFields();
  }

  void _validateFields() {
    setState(() {
      _isNameValid = Validators.isValidName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Edit Admin Profile', style: TextDesign.appBarTitle()),
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
              Text('Update your admin information below.', style: TextDesign.smallText()),
              const SizedBox(height: 32),
              
              AuthLabel(text: 'Username', isValid: _isNameValid),
              AuthTextField(
                controller: _nameController,
                onChanged: (_) => _validateFields(),
                hintText: 'AdminName',
                prefixIcon: Icon(Icons.person_outline, color: theme.onHint, size: 20),
                borderColor: _nameController.text.isNotEmpty && !_isNameValid ? theme.error.withOpacity(0.3) : null,
                errorText: _nameController.text.isNotEmpty && !_isNameValid ? 'Only letters and spaces allowed' : null,
              ),
              const SizedBox(height: 20),
              
              const AuthLabel(text: 'Email Address (Read Only)'),
              AuthTextField(
                controller: TextEditingController(text: widget.admin.email),
                readOnly: true,
                hintText: '',
                prefixIcon: Icon(Icons.email_outlined, color: theme.onHint, size: 20),
                filled: true,
                fillColor: theme.surfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 20),

              const AuthLabel(text: 'Role (Read Only)'),
              AuthTextField(
                controller: TextEditingController(text: widget.admin.role.toUpperCase()),
                readOnly: true,
                hintText: '',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined, color: theme.onHint, size: 20),
                filled: true,
                fillColor: theme.surfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isNameValid ? _saveProfile : null,
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
    final updatedAdmin = widget.admin.copyWith(
      username: _nameController.text.trim(),
    );

    await TaskRunner.run(
      context: context,
      task: () => _ctrl.updateAdminProfile(context, updatedAdmin),
      loadingMessage: "Saving changes...",
      successMessage: "Profile updated successfully!",
    );

    if (mounted) Navigator.pop(context);
  }
}
