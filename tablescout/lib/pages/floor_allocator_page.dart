import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class FloorAllocatorPage extends StatelessWidget {
  const FloorAllocatorPage({super.key});

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
          title: 'Floor Allocator',
          message:
              'The Floor Allocator is currently under construction. Soon you will be able to manage and allocate tables and desks across your store.',
          icon: Icons.dashboard_customize_outlined,
        ),
      ),
    ),
  ),
);
  }
}