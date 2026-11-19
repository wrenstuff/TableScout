import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class CloudPage extends StatelessWidget {
  const CloudPage({super.key});

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
              title: 'Cloud Services',
              message:
                  'Cloud storage and data management are currently under development. Soon you will be able to manage your store data, backups and cloud synchronisation from here.',
              icon: Icons.cloud_outlined,
            ),
          ),
        ),
      ),
    );
  }
}