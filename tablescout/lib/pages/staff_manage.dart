import 'package:flutter/material.dart';
import 'package:tablescout/session/session_manager.dart';
import 'package:provider/provider.dart';
import 'package:tablescout/theme/app_colours.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final List<Map<String, String>> staffMembers = [
    {'username': 'Alex', 'email': 'alex@example.com', 'role': 'MANAGER'},

    {'username': 'Timmy', 'email': 'timmy@example.com', 'role': 'SUPERVISOR'},

    {'username': 'Billy', 'email': 'billy@example.com', 'role': 'STAFF'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      appBar: AppBar(
        backgroundColor: AppColours.panel,
        foregroundColor: AppColours.accent,
        elevation: 0,
        title: const Text(
          'Staff Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Employees',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColours.accent,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Manage your store employees and their roles.',
              style: TextStyle(
                fontSize: 14,
                color: AppColours.accent,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: staffMembers.length,
                itemBuilder: (context, index) {
                  final employee = staffMembers[index];
                  final session = context.read<SessionManager>();

                  final canEdit =
                      session.isAdmin ||
                      (session.isStore &&
                          (employee['role'] == 'MANAGER' ||
                              employee['role'] == 'SUPERVISOR' ||
                              employee['role'] == 'STAFF')) ||
                      (session.isManager &&
                          (employee['role'] == 'SUPERVISOR' ||
                              employee['role'] == 'STAFF'));

                  return Card(
                    color: AppColours.panel,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(12),
                      side: const BorderSide(
                        color: AppColours.border,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColours.accent,
                        child: Text(
                          employee['username']![0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColours.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        employee['username']!,
                        style: const TextStyle(
                          color: AppColours.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Text(
                        '${employee['email']}\n${employee['role']}',
                        style: const TextStyle(
                          color: AppColours.accent,
                          height: 1.5,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: canEdit
                          ? IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColours.accent,
                              ),
                              tooltip: 'Edit employee',
                              onPressed: () {
                                // Editing functionality comes next
                              },
                            )
                          : const Icon(
                            Icons.lock_outline,
                            color: AppColours.accent,
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
