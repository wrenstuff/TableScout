import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tablescout/session/session_manager.dart';
import 'package:tablescout/pages/passwordmanage_page.dart';

class AccountPage extends StatefulWidget {
  final VoidCallback onNavigateToPassword;

  const AccountPage({
    super.key,
    required this.onNavigateToPassword,
    });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>{
  String _currentUsername = '';
  String _currentEmail = '';
  String _currentPhone = '';
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialised) {
      final session = context.read<SessionManager>();

      _currentUsername = session.username ?? '';
      _currentEmail = session.email ?? '';

      _initialised = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();

    final username = _currentUsername.trim();
    final email = _currentEmail.trim();
    final phone = _currentPhone.trim();
    final role = sessionManager.role?.trim() ?? '';
    final storeName = sessionManager.storeName?.trim() ?? '';
    final accountStatus = sessionManager.accountStatus?.trim() ?? '';

    final displayUsername = 
      username.isNotEmpty ? username : 'User';

    final displayEmail = 
      email.isNotEmpty ? email : 'No email available';

    final displayRole = 
      role.isNotEmpty ? _formatRole(role) : 'Not available';

    final displayStore =
      storeName.isNotEmpty ? storeName : 'No store associated';

    final displayAccountStatus =
      accountStatus.isNotEmpty ? _formatRole(accountStatus) : 'Not available';

    final initials = _getInitials(displayUsername);

    final theme = Theme.of(context);
    final colours = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Account',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your personal information and account.',
             style: theme.textTheme.bodyMedium?.copyWith(
              color: colours.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          //Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colours.primaryContainer,
                    child: Text(
                      initials,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colours.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayUsername,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(displayEmail),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                          ),
                          label: Text(role),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          //Person Info
          _sectionHeading(
            context,
            'Personal information',
            'Your contact details and profile information.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _detailRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Username',
                  value: displayUsername,
                  onEdit: _editPersonalInformation,
                ),
                const Divider(height: 1),
                _detailRow(
                  context,
                  icon: Icons.email_outlined,
                  label: 'Email address',
                  value: displayEmail,
                  onEdit: _editPersonalInformation,
                ),
                const Divider(height: 1),
                _detailRow(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                  value: phone.isNotEmpty? phone : 'Not Added',
                  onEdit: _editPersonalInformation,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Account information
          _sectionHeading(
            context,
            'Account information',
            'Your role and workplace details.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _detailRow(
                  context,
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: displayRole,
                ),
                const Divider(height: 1),
                _detailRow(
                  context,
                  icon: Icons.store_outlined,
                  label: 'Store',
                  value: displayStore,
                ),
                const Divider(height: 1),
                _detailRow(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'Account status',
                  value: displayAccountStatus,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Future statistics
          _sectionHeading(
            context,
            'Your activity',
            'A snapshot of your work in TableScout.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.event_outlined,
                  label: 'Events',
                  value: '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  context,
                  icon: Icons.table_restaurant_outlined,
                  label: 'Tables',
                  value: '—',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Security
          _sectionHeading(
            context,
            'Security',
            'Keep your account secure.',
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change password'),
              subtitle: const Text(
                'Update the password used to sign in.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onNavigateToPassword,
            ),
          ),
        ],
      ),
    );
  }


  static Widget _sectionHeading(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
        ],
      ), 
    );  
  }

  static Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 26,
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }

  static void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account editing will be implemented next',
        ),
      ),
    );
  }

  static String _getInitials(String username) {
    final nameParts = username
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .toList();

    if (nameParts.isEmpty) return '?';

    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'
        .toUpperCase();
    }

    final name = nameParts.first;

    return name.length >= 2
      ? name.substring(0,2).toUpperCase()
      : name.toUpperCase();
  }

  static String _formatRole(String role) {
    final formatted = role
      .replaceAll('_', ' ')
      .toLowerCase()
      .trim();

    if (formatted.isEmpty) return 'Not Avaiable';

    return formatted
      .split(' ')
      .map(
        (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  }

  Future<void> _editPersonalInformation() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => _EditPersonalInformationDialog(
        username: _currentUsername,
        email: _currentEmail,
        phone: _currentPhone,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _currentUsername = result['username']!;
      _currentEmail = result['email']!;
      _currentPhone = result['phone']!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Details updated on this page. Database saving is not connected yet.',
        ),
      ),
    );
  }
}
class _EditPersonalInformationDialog extends StatefulWidget {
  final String username;
  final String email;
  final String phone;

  const _EditPersonalInformationDialog({
    required this.username,
    required this.email,
    required this.phone,
  });

  @override
  State<_EditPersonalInformationDialog> createState() =>
      _EditPersonalInformationDialogState();
}

class _EditPersonalInformationDialogState
    extends State<_EditPersonalInformationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _usernameController =
        TextEditingController(text: widget.username);
    _emailController =
        TextEditingController(text: widget.email);
    _phoneController =
        TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit personal information'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}