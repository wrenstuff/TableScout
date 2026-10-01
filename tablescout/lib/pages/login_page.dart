import 'package:flutter/material.dart';
import 'package:tablescout/widgets/login_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wood.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                ),
                child: const LoginWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}