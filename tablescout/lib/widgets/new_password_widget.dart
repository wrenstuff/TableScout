import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tablescout/widgets/auth_container.dart';

class NewPasswordWidget extends StatefulWidget {
  const NewPasswordWidget({super.key});

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
    if (!_formkey.currentState!.validate()) {
      return;
    }

    setState((){
      _loading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if(!mounted) return;

     setState((){
      _loading = false;
    });

    context.go('/login');
  }

  @override

  Widget build(BuildContext context) {
    return AuthContainer(
      boxHeight: 450,
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
          ),

          const SizedBox(height: 15),

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
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Handle password recovery logic here
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF54414E),
                foregroundColor: const Color(0xFFB5BAD0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Submit new password'),
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