// lib/util/settings/settings_view.dart
import 'package:flutter/material.dart';
import 'settings_manager.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = SettingsManager.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: manager.themeMode,
            onChanged: (mode) => manager.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: manager.themeMode,
            onChanged: (mode) => manager.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: manager.themeMode,
            onChanged: (mode) => manager.setThemeMode(mode!),
          ),
        ],
      ),
    );
  }
}