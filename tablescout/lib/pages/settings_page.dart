import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

const double size = 200; // how big the boxes are

class _SettingsPageState extends State<SettingsPage> {
  Widget _settingsBox({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: const Color(0xFFA8A9B3),
        borderRadius: BorderRadius.circular(5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                // ACCOUNT
                _settingsBox(
                  label: 'Account',
                  icon: Icons.person,
                  onTap: () {
                    // Navigate to Account
                  },
                ),

                // STAFF MANAGEMENT
                _settingsBox(
                  label: 'Staff Management',
                  icon: Icons.manage_accounts,
                  onTap: () {
                    // Navigate to Staff Management
                  },
                ),

                // PRIVACY
                _settingsBox(
                  label: 'Privacy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    // Navigate to Privacy
                  },
                ),

                // PASSWORD MANAGEMENT
                _settingsBox(
                  label: 'Password Management',
                  icon: Icons.vpn_key_outlined,
                  onTap: () {
                    // Navigate to Password Management
                  },
                ),

                // CLOUD
                _settingsBox(
                  label: 'Cloud',
                  icon: Icons.cloud_outlined,
                  onTap: () {
                    // Navigate to Cloud
                  },
                ),

                // CUSTOMISE
                _settingsBox(
                  label: 'Customise',
                  icon: Icons.dashboard_customize_outlined,
                  onTap: () {
                    // Navigate to Customise
                  },
                ),

                // NOTIFICATIONS
                _settingsBox(
                  label: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    // Navigate to Notifications
                  },
                ),

                // SIGN OUT
                _settingsBox(
                  label: 'Sign Out',
                  icon: Icons.logout,
                  onTap: () {
                    // Handle signing out
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}