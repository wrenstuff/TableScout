import 'package:flutter/material.dart';
import 'package:tablescout/widgets/login_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: LoginWidget(),
          ),
        ),
      );
  }
}