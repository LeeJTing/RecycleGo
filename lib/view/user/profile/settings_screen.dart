import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/UserSettings.dart';
import 'package:recycle_go/utils/async_task_runner.dart';

class SettingsScreen extends StatefulWidget {
  final UserSettings settings;
  final Function(UserSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text('Settings', style: TextDesign.appBarTitle()),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: TextDesign.headingTwo()),
            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.palette_outlined,
              title: 'Theme Mode',
              subtitle: _currentSettings.themeMode,
              trailing: DropdownButton<String>(
                value: _currentSettings.themeMode,
                underline: const SizedBox(),
                items: ['light mode', 'dark mode'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextDesign.normalText()),
                  );
                }).toList(),
                onChanged: (value) => _updateSetting(_currentSettings.copyWith(themeMode: value)),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: _currentSettings.language == 'en' ? 'English' : 'Other',
              trailing: DropdownButton<String>(
                value: _currentSettings.language,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) => _updateSetting(_currentSettings.copyWith(language: value)),
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Notifications', style: TextDesign.headingTwo()),
            const SizedBox(height: 16),
            _buildSwitchTile(
              icon: Icons.notifications_none_outlined,
              title: 'General Notifications',
              value: _currentSettings.notification,
              onChanged: (value) => _updateSetting(_currentSettings.copyWith(notification: value)),
            ),
            _buildSwitchTile(
              icon: Icons.place_outlined,
              title: 'Station Updates',
              value: _currentSettings.notifyStation,
              onChanged: (value) => _updateSetting(_currentSettings.copyWith(notifyStation: value)),
            ),
            _buildSwitchTile(
              icon: Icons.gavel_outlined,
              title: 'Appeal Requests',
              value: _currentSettings.notifyAppealRequest,
              onChanged: (value) => _updateSetting(_currentSettings.copyWith(notifyAppealRequest: value)),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Save Settings', style: TextDesign.buttonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final theme = AppThemes.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextDesign.mediumText()),
                Text(subtitle, style: TextDesign.smallText(color: theme.onHint)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = AppThemes.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextDesign.mediumText())),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  void _updateSetting(UserSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
  }

  void _saveSettings() async {
    await TaskRunner.run(
      context: context,
      task: () async {
        await UserSettingsModel().updateSettings(_currentSettings);
        // Apply theme immediately
        AppThemes().setTheme(_currentSettings.themeMode);
        widget.onSettingsChanged(_currentSettings);
      },
      loadingMessage: "Applying settings...",
      successMessage: "Settings updated!",
    );
  }
}
