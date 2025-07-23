import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vidrocket_pro/providers/theme_provider.dart';
import 'package:vidrocket_pro/widgets/custom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/', (route) => false);
          }
        },
      ),
    );
  }
}
