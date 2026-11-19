import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class PasswordManagementPage extends StatelessWidget {
  const PasswordManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstructionBackground(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 550,
            ),
            child: const ConstructionTooltip(
              title: 'Password Management',
              message:
                  'Password management is currently under development. Soon you will be able to securely update your password and manage your account security settings.',
              icon: Icons.lock_outline,
            ),
          ),
        ),
      ),
    );
  }
}