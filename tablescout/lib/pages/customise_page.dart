import 'package:flutter/material.dart';

class CustomisePage extends StatelessWidget {
  const CustomisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customise',

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text('Customize your store settings and preferences here.'),
        ],
      ),
    );
  }
}