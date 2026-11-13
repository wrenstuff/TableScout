import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:tablescout/widgets/auth_container.dart';
import 'dart:convert';
import 'package:tablescout/app_config.dart';

class PasswordRecoveryWidget extends StatefulWidget {
  const PasswordRecoveryWidget({super.key});

  @override
  State<PasswordRecoveryWidget> createState() =>
  _PasswordRecoveryWidgetState();

}
  class _PasswordRecoveryWidgetState
   extends State<PasswordRecoveryWidget>
{
  final _emailController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override 
  void dispose(){
    _emailController.dispose();
    super.dispose();
  }
  Future<void> _submitEmail() async {
    if (!_formkey.currentState!.validate())return;

    setState(() {
      _isLoading = true;
    });
  

  final email = _emailController.text.trim();
  
  try {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.httpBaseUrl}/tablescout/pages/password-recovery',
      ),
      headers:{
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'email': email
      }),
    );
    final result = jsonDecode(response.body);

    if (!mounted) return;

    if (response.statusCode >=200 &&
    response.statusCode <300 && result['success']== true ){
      context.go('/recover-code', extra: email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] ?? 'Request not processed'
          ),
        ),
      );
    }
  } catch (e){
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text ('Cannot connect to server')
      ),
    );
  } finally {
    if (mounted){
      setState((){
        _isLoading = false;
      });
      
    }
  }

}
  @override
  Widget build(BuildContext context) {
    return AuthContainer(
      boxHeight: 450,
      child: Form(
        key: _formkey,
        child: Column(
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
          const SizedBox(height: 65,),
          

          const Text(
            'Email',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value){
              if (value == null || value.trim().isEmpty){
                return 'Please enter your email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF54414E),
                foregroundColor: const Color(0xFFB5BAD0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isLoading ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
              : const Text('SUBMIT EMAIL'),
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