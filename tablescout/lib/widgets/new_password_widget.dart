import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tablescout/widgets/auth_container.dart';
import 'package:tablescout/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewPasswordWidget extends StatefulWidget {
  final String resetToken;

  const NewPasswordWidget({
    super.key,
    required this.resetToken,
  });

  @override
  State<NewPasswordWidget> createState() => _NewPasswordWidgetState();
  
}

class _NewPasswordWidgetState extends State<NewPasswordWidget> {
  //variable init
  final _formkey = GlobalKey<FormState>();
  final _passwordcontrol = TextEditingController();
  final _confirmpasswordcontrol = TextEditingController();

  
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;

  String? _errorMessage;
  @override
  void dispose(){
    _passwordcontrol.dispose();
    _confirmpasswordcontrol.dispose();
    super.dispose();
  }
   Future<void> _submitPassword() async {
    print('Submit password button clicked');
    if (!_formkey.currentState!.validate()) {
      print('Password validation failed');
      return;
    }
    print('Password validation passed');
    setState((){
      _loading = true;
      _errorMessage = null;
    });

    try {
       print('Sending password reset request...');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.httpBaseUrl}/tablescout/pages/reset-password',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reset_token': widget.resetToken,
          'new_password': _passwordcontrol.text,
        }),
      );
      final data =jsonDecode(response.body);
      print('Reset password status: ${response.statusCode}');
      print('Reset password response: ${response.body}');

      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated!'),
          ),
        );
        context.go('/login');
      }else {
        setState(() {
          _errorMessage = data['message'] ?? 'Password reset failed';
        });
      }
    }
    catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = "Cannot connect to login server";
      });
    } finally{
      if (mounted){
        setState(() {
          _loading = false;
        });
      }
    }
  }
  @override

  Widget build(BuildContext context) {
    return AuthContainer(
      boxHeight: 460,
      child: Form(
        key: _formkey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

          const Text(
            'TableScout',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF282828),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Password Recovery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Enter new Password',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),
            // first pass
           TextFormField(
            controller: _passwordcontrol,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              hintText: 'Enter new password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
              ),
              border: OutlineInputBorder(),
            ),
            validator: (value){
              if (value == null || value.isEmpty){
                return 'Please enter a new password';
              }
              if (value.length < 8) {
                return 'Must be 8 characters';
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(value)){
                return 'password must have 1 symbol';
              }
              return null;
            },
          ),

          const SizedBox(height: 15),
          // confirm pass
          TextFormField(
            controller: _confirmpasswordcontrol,
            obscureText: _hideConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _hideConfirmPassword = !_hideConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(),
              
            ),
            validator: (value){
              if (value == null || value.isEmpty){
                return 'Please confirm the password';
              }
              if (value != _passwordcontrol.text) {
                return ' Passwords do not match';
              }
              
              return null;
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submitPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF54414E),
                foregroundColor: const Color(0xFFB5BAD0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _loading
              ?const CircularProgressIndicator(
                color: Color(0xFFB5BAD0),
              )
              : const Text('Submit New Password')
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: Color(0xFF54414E),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}