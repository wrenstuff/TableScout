import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordRecoveryWidget extends StatelessWidget {
  const PasswordRecoveryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFB5BAD0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          const Text(
            'TableScout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF282828),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Password Recovery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),

            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Handle password recovery logic here
                context.go('/recover-code');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF54414E),
                foregroundColor: const Color(0xFFB5BAD0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('SUBMIT EMAIL'),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: Color(0xFF54414E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}