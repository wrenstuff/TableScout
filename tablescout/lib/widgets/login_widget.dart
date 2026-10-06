import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// import 'package:tablescout/session/session_manager.dart';
// import 'package:tablescout/pages/signup_page.dart';
import 'package:tablescout/services/auth_service.dart';
import 'package:tablescout/widgets/nav_bar.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    //if (!_formKey.currentState!.validate()) {
    //  return;
    //}
    //
    //final sessionManager = context.read<SessionManager>();
    //
    //final success = await sessionManager.login(
    //  _usernameController.text.trim(),
    //  _passwordController.text,
    //);
    //
    //if (!mounted) return;
    //
    //if (success) {
    //  context.go('/app');
    //} else {
    //  ScaffoldMessenger.of(context).showSnackBar(
    //    const SnackBar(
    //      content: Text('Incorrect username or password'),
    //    ),
    //  );
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const NavBar(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  //border styling
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF54414E),
          width: 1,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF54414E),
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF54414E),
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),

      decoration: BoxDecoration(
        color: const Color(0xFFB5BAD0),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Form(
        key: _formKey,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TableScout title
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

            // Welcome message
            const Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Log in to your TableScout account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            // Email label
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: _inputDecoration(
                hintText: 'Enter your email',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // Password label
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(
                hintText: 'Enter your password',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Password reset to sort out!!
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF54414E),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null :_login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF54414E),
                  foregroundColor: const Color(0xFFB5BAD0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                  : const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Sign up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Color(0xFF54414E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}