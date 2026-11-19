import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tablescout/widgets/auth_container.dart';
import 'package:tablescout/app_config.dart';

class RecoverCodeWidget extends StatefulWidget {
  final String email;
  
  const RecoverCodeWidget({super.key, required this.email,});

  @override
  State<RecoverCodeWidget> createState() => _RecoverCodeWidgetState();
}

class _RecoverCodeWidgetState extends State<RecoverCodeWidget> {
  final _formkey = GlobalKey<FormState>();
  final _codeChecker = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  @override 
  void dispose(){
    _codeChecker.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async{
    if (!_formkey.currentState!.validate()){
      return;
    }
    setState((){
      _loading =true;
      _errorMessage =null;
    });

    try{
      final response = await http.post(
        
        Uri.parse(
          '${AppConfig.httpBaseUrl}/tablescout/pages/verify-recovery-code',
        ),
        headers: {
          'Content-type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'code': _codeChecker.text.trim(),
        }),
      );
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      final data = jsonDecode(response.body);

      if (!mounted)  return;

      if (response.statusCode == 200 && data ['success'] == true){
        final resetToken = data['reset_token'];

        if (resetToken == null){
          setState(() {
            _errorMessage = "Code not verified";
          });
          return;
        }
        context.go('/new-password', extra: resetToken);
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'invalid code, try again';
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Recovery code error: $error');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = "Something went wrong. Check the debug console.";
      });
    } finally {
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
      boxHeight: 450,
      child: Form(
        key: _formkey,
        child:Column(
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

          const SizedBox(height: 65),

          const Text(
            'Recovery code',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _codeChecker,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              hintText: 'Enter your 6 digit recovery code',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value){
              if (value ==null || value.isEmpty){
                return 'please enter your 6 digit recovery code';
              }
              
              if (value.length !=6){
                return 'recovery code lengeth is not 6 digits please enter the correct number';
              }
              return null;
            },
          ),
           if (_errorMessage != null)... [
            const SizedBox(height: 12),
            Text(_errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize:13,
            ),
            textAlign: TextAlign.center,
            )
           ],

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF54414E),
                foregroundColor: const Color(0xFFB5BAD0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _loading
              ? const CircularProgressIndicator(
                color: Color(0xFFB5BAD0),
              )
              : const Text ('Submit code'),
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