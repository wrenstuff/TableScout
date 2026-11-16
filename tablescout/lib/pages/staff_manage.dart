import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/services/staffmanage_service.dart';
import 'package:provider/provider.dart';

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
      return const Center(child: CircularProgressIndicator());
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
              child: const Text('Page failed to load'),
            ),
          ],
        ),
      );
    }

    if (staffMembers.isEmpty) {
      return const Center(child: Text('no staff were found.'));
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Username')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Actions')),
          ],
          rows: staffMembers.map((staff) {
            return DataRow(
              cells: [
                DataCell(Text(staff['username']?.toString() ?? '')),
                DataCell(Text(staff['email']?.toString() ?? '')),
                DataCell(Text(staff['role']?.toString() ?? '')),
                DataCell(staff['can_edit'] == true
                ? IconButton(
                  tooltip: 'Edit staff member',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editStaff(staff),
                )
                : const SizedBox.shrink(),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

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

            Expanded(child: _buildStaffContent()),
          ],
        ),
      ),
    );
  }
}
