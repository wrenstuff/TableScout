import 'package:flutter/material.dart';
import 'package:tablescout/widgets/signup_widget.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: SignupWidget(),
        ),
      ),
    );
  }
}