import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/services/staffmanage_service.dart';
import 'package:provider/provider.dart';
import 'package:tablescout/theme/app_colours.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  List<Map<String, dynamic>> staffMembers = [];

  bool isLoading = true;
  String? errorMessage;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaff();
    });
  }

  Future<void> _loadStaff() async {
    final session = context.read<SessionManager>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Currently you are not logged in, Log in again';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final staff = await StaffService.getStaff(token: token);

      if (!mounted) return;

      setState(() {
        staffMembers = staff;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _editStaff(Map<String, dynamic> staff) async {
    final session = context.read<SessionManager>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("try logging in again")));
      return;
    }
      debugPrint('STAFF MEMBER DATA: $staff');
      debugPrint('STAFF USER ID: ${staff['userid']}');
    final staffId = int.tryParse(staff['userid'].toString());

    if (staffId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid Staff ID")));
      return;
    }
    final usernameController = TextEditingController(
      text: staff['username']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: staff['email']?.toString() ?? '',
    );

    final editableRoles = (staff['editable_roles'] as List?)
    ?.map((role)=> role.toString())
    .toList() ?? [];

    String selectedRole =
    staff['role']?.toString().toUpperCase() ?? '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext){
        return StatefulBuilder(
          builder: (context, setDialogueState){
            return AlertDialog(
              title: const Text('Edit Staff member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText:'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: editableRoles.contains(selectedRole)
                      ? selectedRole
                      : null,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: editableRoles.map((role){
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null){
                          setDialogueState((){
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: (){
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('cancel'),
                ),

                ElevatedButton(
                  onPressed: (){
                    Navigator.pop(dialogContext,{
                      'username': usernameController.text.trim(),
                      'email': emailController.text.trim(),
                      'role': selectedRole,
                    });
                  },
                  child: const Text('Save changes'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    emailController.dispose();

    if (result == null) return;

    if(result['username']!.isEmpty ||
      result['email']!.isEmpty ||
      !result['email']!.contains('@')||
      result['role']!.isEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid username email and role'),
          ),
        );
        return;
      }
      try{
        await StaffService.updateStaff(
          token: token,
          staffId: staffId,
          username: result['username']!,
          email: result['email']!,
          role: result['role']!,
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated successfully'),
          ),
        );

        await _loadStaff();
      }catch (e) {
        if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text (
            e.toString().replaceFirst('Exception: ', ''),
          ),
        )
      );
    }
  }
  
 
  Widget _buildStaffContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStaff,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (staffMembers.isEmpty) {
      return const Center(
        child: Text('No staff were found.'),
      );
    }

    final session = context.read<SessionManager>();

    return ListView.builder(
      itemCount: staffMembers.length,
      itemBuilder: (context, index) {
        final employee = staffMembers[index];

        final username = employee['username']?.toString() ?? '';
        final email = employee['email']?.toString() ?? '';
        final role = employee['role']?.toString() ?? '';

        final canEdit =
            session.isAdmin ||
            (session.isStore &&
                (role == 'MANAGER' ||
                    role == 'SUPERVISOR' ||
                    role == 'STAFF')) ||
            (session.isManager &&
                (role == 'SUPERVISOR' ||
                    role == 'STAFF'));

        return Card(
          color: AppColours.panel,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                username.isNotEmpty
                    ? username[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColours.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              username,
              style: const TextStyle(
                color: AppColours.accent,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              '$email\n$role',
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
                    onPressed: () => _editStaff(employee),
                  )
                : const Icon(
                    Icons.lock_outline,
                    color: AppColours.accent,
                  ),
          ),
        );
      },
    );
  }

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
              child: _buildStaffContent(),
            ),
          ],
        ),
      ),
    );
  }
}
