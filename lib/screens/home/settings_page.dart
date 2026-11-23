// ignore_for_file: unused_field, unused_element, deprecated_member_use, use_build_context_synchronously, curly_braces_in_flow_control_structures, unused_local_variable, sort_child_properties_last, avoid_print, non_constant_identifier_names, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/language_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('PREFERENCES'),
          Consumer<LanguageProvider>(
            builder: (context, langProvider, child) => _buildSettingTile(
              title: 'Language',
              subtitle: 'Select your preferred language',
              icon: Icons.language,
              trailing: DropdownButton<AppLanguage>(
                value: langProvider.currentLanguage,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                onChanged: (AppLanguage? newValue) {
                  if (newValue != null) {
                    langProvider.setLanguage(newValue);
                  }
                },
                items: AppLanguage.values.map((AppLanguage lang) {
                  return DropdownMenuItem<AppLanguage>(
                    value: lang,
                    child: Text(
                      lang.name.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.border),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          _buildSettingTile(
            title: 'Push Notifications',
            subtitle: 'Get alerts for new chat messages and site updates',
            icon: Icons.notifications_active_outlined,
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              activeColor: AppColors.border,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          _buildSettingTile(
            title: 'Dark Mode',
            subtitle: 'Switch between light and dark themes',
            icon: Icons.dark_mode_outlined,
            trailing: Switch.adaptive(
              value: _darkMode,
              activeColor: AppColors.border,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ),
          const SizedBox(height: 30),
          _buildSectionHeader('SECURITY'),
          _buildSettingTile(
            title: 'Change Password',
            subtitle: 'Update your account security credentials',
            icon: Icons.lock_outline,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset link sent to your email')),
              );
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              elevation: 0,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showLogoutDialog(context),
            child: const Text(
              'SIGN OUT FROM ALL DEVICES',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'App Version 2.1.0 (Stable)',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.border,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.border, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to securely clear your session and sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.instance.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
