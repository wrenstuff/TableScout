import 'package:flutter/material.dart';

import 'package:tablescout/theme/app_colours.dart';
import 'package:tablescout/widgets/construction_tooltip.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
              title: 'Notifications',
              message:
                  'Notification settings are currently under development. Soon you will be able to manage store alerts, event reminders and important account notifications from here.',
              icon: Icons.notifications_outlined,
            ),
          ),
        ),
      ),
    );
  }
}