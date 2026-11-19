import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
              title: 'Privacy Settings',
              message:
                  'Privacy controls and data management options are currently under development. You will soon be able to manage how your store information and personal data are handled.',
              icon: Icons.shield_outlined,
            ),
          ),
        ),
      ),
    );
  }
}