import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class CustomisePage extends StatelessWidget {
  const CustomisePage({super.key});

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
              title: 'Customise',
              message:
                  'Store customisation is currently under development. Soon you will be able to personalise your TableScout experience, including store preferences, appearance and display settings.',
              icon: Icons.palette_outlined,
            ),
          ),
        ),
      ),
    );
  }
}