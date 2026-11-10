import 'package:flutter/material.dart';

class PasswordManagementPage extends StatelessWidget {
  const PasswordManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text('Manage store employees and their roles here.'),
        ],
      ),
    );
  }
}