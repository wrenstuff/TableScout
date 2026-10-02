import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.black),
                ),
              ]
            ),
            Column(
              children: [ // Top row of settings
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Account'),
                  onTap: () {
                    // Handle account settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_ind),
                  title: const Text('Staff Management'),
                  onTap: () {
                    // Handle staff management settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_person),
                  title: const Text('Privacy'),
                  onTap: () {
                    // Handle privacy settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Password Management'),
                  onTap: () {
                    // Handle password management settings tap
                  },
                ),

              ]
            ),
            Column(
              children: [ // Bottom row of settings
                ListTile(
                  leading: const Icon(Icons.wb_cloudy),
                  title: const Text('Cloud'),
                  onTap: () {
                    // Handle cloud settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Customise'),
                  onTap: () {
                    // Handle customise settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  onTap: () {
                    // Handle notifications settings tap
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    // Handle sign out
                  },
                ),
              ]
            ),
          ],
        )
      ),
    );
  }
}