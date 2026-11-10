import 'package:flutter/material.dart';
import 'package:tablescout/widgets/recover_code_widget.dart';
import 'package:tablescout/widgets/auth_container.dart';

class RecoverCodePage extends StatefulWidget {
  const RecoverCodePage({super.key});

  @override
  State<RecoverCodePage> createState() => _RecoverCodePageState();
}

class _RecoverCodePageState extends State<RecoverCodePage> {
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wood.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: const SizedBox(
                width: 500,
                height: 570,
                child: RecoverCodeWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}