import 'package:flutter/material.dart';
import 'package:tablescout/session/session_manager.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: const Text('Staff Management')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Employees',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            const Text(
              'Manage your store employees and their roles.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: staffMembers.length,
                itemBuilder: (context, index) {
                  final employee = staffMembers[index];
                  final session = context.read<SessionManager>();

                  final canEdit =
                      (session.isStore &&
                          (employee['role'] == 'MANAGER' ||
                              employee['role'] == 'SUPERVISOR' ||
                              employee['role'] == 'STAFF')) ||
                      (session.isManager &&
                          (employee['role'] == 'SUPERVISOR' ||
                              employee['role'] == 'STAFF'));

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(employee['username']![0].toUpperCase()),
                      ),
                      title: Text(employee['username']!),
                      subtitle: Text(
                        '${employee['email']}\n${employee['role']}',
                      ),
                      isThreeLine: true,
                      trailing: canEdit
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit employee',
                              onPressed: () {
                                // Editing functionality comes next
                              },
                            )
                          : const Icon(Icons.lock_outline),
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
