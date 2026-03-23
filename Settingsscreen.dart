import 'package:flutter/cupertino.dart';
import 'package:iyadunni_shopmore/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iyadunni_shopmore/themeprovider.dart';
import 'package:provider/provider.dart'; // Add this import

import 'dart:io' show Platform;
import 'package:iyadunni_shopmore/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// REUSABLE CROSS-PLATFORM SETTING ITEM
class PlatformSettingItem extends StatelessWidget {
  final IconData iosIcon;
  final IconData androidIcon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;

  const PlatformSettingItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iosIcon = CupertinoIcons.gear,
    this.androidIcon = Icons.settings,
    this.iconColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Container(
      decoration: BoxDecoration(
        color: isIOS ? CupertinoColors.systemBackground : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isIOS ? 10 : 12),
        border: isIOS ? null : Border.all(color: Colors.grey.shade300),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(isIOS ? iosIcon : androidIcon, color: iconColor, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isIOS ? 17 : 18,
                  fontWeight: isIOS ? FontWeight.normal : FontWeight.w500,
                  color: isIOS ? CupertinoColors.label : Colors.black87,
                ),
              ),
            ),
            isIOS
                ? CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: CupertinoColors.systemBlue,
                  )
                : Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: Colors.blue,
                  ),
          ],
        ),
      ),
    );
  }
}

// USING THE REUSABLE WIDGET
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),

            // Dark Mode
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return PlatformSettingItem(
                  title: 'Dark Mode',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  iosIcon: CupertinoIcons.moon_fill,
                  androidIcon: Icons.dark_mode,
                  iconColor: Colors.blue,
                );
              },
            ),

            // Notifications
            PlatformSettingItem(
              title: 'Notifications',
              value: true,
              onChanged: (value) {},
              iosIcon: CupertinoIcons.bell_fill,
              androidIcon: Icons.notifications,
              iconColor: Colors.green,
            ),

            // Sound
            PlatformSettingItem(
              title: 'Sound',
              value: true,
              onChanged: (value) {},
              iosIcon: CupertinoIcons.volume_up,
              androidIcon: Icons.volume_up,
              iconColor: Colors.orange,
            ),

            // Vibration
            PlatformSettingItem(
              title: 'Vibration',
              value: false,
              onChanged: (value) {},
              iosIcon: CupertinoIcons.waveform,
              androidIcon: Icons.vibration,
              iconColor: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
